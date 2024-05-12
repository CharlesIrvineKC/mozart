defmodule Mozart.ProcessEngine do
  use GenServer

  require Logger

  alias Mozart.ProcessEngine
  alias Mozart.ProcessService, as: PS
  alias Mozart.ProcessModelService, as: PMS
  alias Mozart.Data.ProcessState
  alias Mozart.Data.Task
  alias Ecto.UUID

  ## Client API

  def start_link(uid, model_name, data, parent \\ nil) do
    {:ok, pid} = GenServer.start_link(__MODULE__, {uid, model_name, data, parent})
    {:ok, pid, uid}
  end

  def execute(ppid) do
    GenServer.cast(ppid, :execute)
  end

  def start_supervised_pe(model_name, data, parent \\ nil) do
    uid = UUID.generate()

    child_spec = %{
      id: MyProcessEngine,
      start: {Mozart.ProcessEngine, :start_link, [uid, model_name, data, parent]},
      restart: :transient
    }

    DynamicSupervisor.start_child(ProcessEngineSupervisor, child_spec)
  end

  def get_state(ppid) do
    GenServer.call(ppid, :get_state)
  end

  def get_uid(ppid) do
    GenServer.call(ppid, :get_uid)
  end

  def get_model(ppid) do
    GenServer.call(ppid, :get_model)
  end

  def get_data(ppid) do
    GenServer.call(ppid, :get_data)
  end

  def get_task_instances(ppid) do
    GenServer.call(ppid, :get_task_instances)
  end

  def complete_user_task(ppid, task_uid, data) do
    GenServer.cast(ppid, {:complete_user_task, task_uid, data})
  end

  def set_data(ppid, data) do
    GenServer.cast(ppid, {:set_data, data})
  end

  def is_complete(ppid) do
    GenServer.call(ppid, :is_complete)
  end

  def notify_child_complete(parent_pid, sub_process_name, data) do
    GenServer.cast(parent_pid, {:notify_child_complete, sub_process_name, data})
  end

  ## GenServer callbacks

  def init({uid, model_name, data, parent}) do
    pe_recovered_state = PS.get_cached_state(uid)

    state =
      pe_recovered_state ||
        %ProcessState{
          model_name: model_name,
          data: data,
          uid: uid,
          parent: parent
        }

    PS.register_process_instance(uid, self())

    if pe_recovered_state do
      Logger.warning("Restart process instance [#{model_name}][#{uid}]")
    else
      Logger.info("Start process instance [#{model_name}][#{uid}]")
    end

    {:ok, state}
  end

  def handle_call(:is_complete, _from, state) do
    {:reply, state.complete, state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:get_uid, _from, state) do
    {:reply, state.uid, state}
  end

  def handle_call(:get_data, _from, state) do
    {:reply, state.data, state}
  end

  def handle_call(:get_task_instances, _from, state) do
    {:reply, state.task_instances, state}
  end

  def handle_cast({:complete_user_task, task_uid, return_data}, state) do
    task_instance = get_task_instance(task_uid, state)

    state =
      if task_instance do
        data = Map.merge(state.data, return_data)
        state = Map.put(state, :data, data)

        task_instances = Map.delete(state.task_instances, task_uid)

        state = Map.put(state, :task_instances, task_instances)

        state =
          if task_instance.next,
            do: process_next_task(state, task_instance.next, task_instance.name),
            else: state

        Logger.info("Complete user task [#{task_instance.name}][#{task_instance.uid}]")
        execute_process(state)
      else
        state
      end

    {:noreply, state}
  end

  def handle_cast(:execute, state) do
    model = PMS.get_process_model(state.model_name)
    state = process_next_task(state, model.initial_task)
    state = execute_process(state)
    {:noreply, state}
  end

  def handle_cast({:notify_child_complete, sub_process_name, child_data}, state) do
    {_uid, task_instance} =
      Enum.find(state.task_instances, fn {_uid, ti} -> ti.sub_process == sub_process_name end)

    task_instance = Map.put(task_instance, :complete, true)

    task_instances = Map.put(state.task_instances, task_instance.uid, task_instance)

    state =
      state |> Map.put(:task_instances, task_instances) |> Map.put(:data, child_data)

    state = execute_process(state)
    {:noreply, state}
  end

  def handle_cast({:set_data, data}, state) do
    {:noreply, Map.put(state, :data, data)}
  end

  def terminate(reason, state) do
    {reason_code, _stack} = reason

    Logger.warning(
      "Process instance terminated [#{reason_code}][#{state.model_name}][#{state.uid}]"
    )

    PS.cache_pe_state(state.uid, state)
    Process.sleep(50)
  end

  ## callback utilities

  defp process_new_next_task(state, next_task_name, previous_task_name) do
    new_task_i = get_new_task_instance(next_task_name, state)

    new_task_i =
      if new_task_i.type == :join do
        Map.put(
          new_task_i,
          :inputs,
          List.delete(new_task_i.inputs, previous_task_name)
        )
      else
        new_task_i
      end

    # state = Map.put(state, :task_instances, [new_task_i | state.task_instances])
    state =
      Map.put(state, :task_instances, Map.put(state.task_instances, new_task_i.uid, new_task_i))

    if new_task_i.type == :user, do: PS.insert_user_task(new_task_i)

    if new_task_i.type == :sub_process do
      data = state.data
      {:ok, process_pid, _uid} = start_supervised_pe(new_task_i.sub_process, data, self())
      execute(process_pid)
      Map.put(state, :children, [process_pid | state.children])
    else
      state
    end

    Logger.info("New task instance [#{new_task_i.name}][#{new_task_i.uid}]")

    state
  end

  def process_next_task(state, next_task_name, previous_task_name \\ nil) do
    existing_task_i = get_existing_task_instance(state, next_task_name)

    if existing_task_i && existing_task_i.type == :join do
      process_existing_join_next_task(state, existing_task_i, previous_task_name)
    else
      process_new_next_task(state, next_task_name, previous_task_name)
    end
  end

  defp process_next_task_list(state, [], _parent_name) do
    state
  end

  defp process_next_task_list(state, [task_name | rest], parent_name) do
    state = process_next_task(state, task_name, parent_name)
    process_next_task_list(state, rest, parent_name)
  end

  defp get_existing_task_instance(state, task_name) do
    result =
      Enum.find(state.task_instances, fn {_uid, task_i} -> task_i.name == task_name end)

    if result do
      {_uid, task_instance} = result
      task_instance
    end
  end

  defp process_existing_join_next_task(state, existing_task_i, previous_task_name) do
    ## delete previous task name from inputs
    existing_task_i =
      Map.put(
        existing_task_i,
        :inputs,
        List.delete(existing_task_i.inputs, previous_task_name)
      )

    ## Update existing task instance in state
    Map.put(
      state,
      :task_instances,
      Map.put(state.task_instances, existing_task_i.uid, existing_task_i)
    )
  end

  defp complete_service_task(task, state) do
    data = task.function.(state.data)
    state = Map.put(state, :data, data)

    task_instances = Map.delete(state.task_instances, task.uid)

    state = Map.put(state, :task_instances, task_instances)

    state = if task.next, do: process_next_task(state, task.next, task.name), else: state

    Logger.info("Complete service task [#{task.name}[#{task.uid}]")

    execute_process(state)
  end

  defp complete_parallel_task_i(task_i, state) do
    task_instances = Map.delete(state.task_instances, task_i.uid)

    state = Map.put(state, :task_instances, task_instances)

    next_states = task_i.multi_next

    state = process_next_task_list(state, next_states, task_i.name)

    Logger.info("Complete parallel task [#{task_i.name}]")

    execute_process(state)
  end

  defp complete_joint_task(task_i, state) do
    task_instances = Map.delete(state.task_instances, task_i.uid)

    state = Map.put(state, :task_instances, task_instances)

    state = process_next_task(state, task_i.next, task_i.name)

    Logger.info("Complete join task [#{task_i.name}]")

    execute_process(state)
  end

  defp complete_choice_task(task, state) do
    next_task_name =
      Enum.find_value(
        task.choices,
        fn choice -> if choice.expression.(state.data), do: choice.next end
      )

    state = process_next_task(state, next_task_name, task.name)

    task_instances = Map.delete(state.task_instances, task.uid)

    state = Map.put(state, :task_instances, task_instances)

    Logger.info("Complete choice task [#{task.name}][#{task.uid}]")

    execute_process(state)
  end

  defp complete_subprocess_task_i(task_i, state) do
    data = Map.merge(task_i.data, state.data)
    state = Map.put(state, :data, data)

    task_instances = Map.delete(state.task_instances, task_i.uid)

    state = Map.put(state, :task_instances, task_instances)

    state = if task_i.next, do: process_next_task(state, task_i.next, task_i.name), else: state

    Logger.info("Complete subprocess task [#{task_i.name}][#{task_i.uid}]")

    execute_process(state)
  end

  defp get_task_def(task_name, state) do
    model = PMS.get_process_model(state.model_name)
    Enum.find(model.tasks, fn task -> task.name == task_name end)
  end

  defp get_task_instance(task_uid, state) do
    Map.get(state.task_instances, task_uid)
  end

  defp get_new_task_instance(task_name, state) do
    get_task_def(task_name, state)
    |> Map.put(:uid, Ecto.UUID.generate())
    |> Map.put(:process_uid, state.uid)
  end

  defp get_complete_able_task(state) do
    result = Enum.find(state.task_instances, fn {_uid, task_i} -> Task.complete_able(task_i) end)

    if result do
      {_uid, task_i} = result
      task_i
    end
  end

  defp work_remaining(state) do
    state.task_instances != %{}
  end

  defp execute_process(state) do
    if work_remaining(state) do
      complete_able_task_i = get_complete_able_task(state)

      if complete_able_task_i do
        cond do
          complete_able_task_i.type == :service ->
            complete_service_task(complete_able_task_i, state)

          complete_able_task_i.type == :choice ->
            complete_choice_task(complete_able_task_i, state)

          complete_able_task_i.type == :sub_process ->
            complete_subprocess_task_i(complete_able_task_i, state)

          complete_able_task_i.type == :parallel ->
            complete_parallel_task_i(complete_able_task_i, state)

          complete_able_task_i.type == :join ->
            complete_joint_task(complete_able_task_i, state)
        end
      else
        state
      end
    else
      ## no work remaining so process is complete
      # if process instance has a parent process
      if state.parent do
        ProcessEngine.notify_child_complete(state.parent, state.model_name, state.data)
      end

      state = Map.put(state, :complete, true)

      Logger.info("Process complete [#{state.model_name}][#{state.uid}]")

      PS.process_completed_process_instance(state)
      state
    end
  end
end
