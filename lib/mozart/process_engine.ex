defmodule Mozart.ProcessEngine do
  use GenServer

  alias Mozart.ProcessEngine
  alias Mozart.ProcessService
  alias Mozart.Data.ProcessState
  alias Mozart.Data.Task
  alias Mozart.UserTaskService
  alias Mozart.ProcessModelService
  alias Ecto.UUID

  ## Client API

  def start_link(model, data, parent \\ nil) do
    GenServer.start_link(__MODULE__, {model, data, parent})
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

  def complete_user_task(ppid, task_id, data) do
    GenServer.cast(ppid, {:complete_user_task, task_id, data})
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

  def init({model, data, parent}) do
    uid = UUID.generate()

    state = %ProcessState{
      model: model,
      data: data,
      uid: uid,
      task_instances: [],
      parent: parent
    }

    state = process_next_task(state, state.model.initial_task)
    ProcessService.register_process_instance(uid, self())
    state = execute_process(state)
    {:ok, state}
  end

  defp process_next_task_list(state, [], _parent_name) do
    state
  end

  defp process_next_task_list(state, [task_name | rest], parent_name) do
    state = process_next_task(state, task_name, parent_name)
    process_next_task_list(state, rest, parent_name)
  end

  defp get_existing_task_instance(state, task_name) do
    Enum.find(state.task_instances, fn ti -> ti.name == task_name end)
  end

  defp process_next_task(state, next_task_name, previous_task_name \\ nil) do
    existing_task_i = get_existing_task_instance(state, next_task_name)
    task_i = get_task_def(next_task_name, state)

    state =
      if existing_task_i && existing_task_i.type == :join do
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
          Enum.map(
            state.task_instances,
            fn ti -> if ti.name == existing_task_i.name, do: existing_task_i, else: ti end
          )
        )
      else
        task_i =
          Map.put(
            task_i,
            :inputs,
            List.delete(task_i.inputs, previous_task_name)
          )
        Map.put(state, :task_instances, [task_i | state.task_instances])
      end

    if task_i.type == :user, do: UserTaskService.insert_user_task(task_i)

    if task_i.type == :sub_process do
      sub_process_model = ProcessModelService.get_process_model(task_i.sub_process)
      data = state.data
      {:ok, process_pid} = start_link(sub_process_model, data, self())
      Map.put(state, :children, [process_pid | state.children])
    else
      state
    end

  end

  def handle_call(:is_complete, _from, state) do
    {:reply, state.complete, state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:get_model, _from, state) do
    {:reply, state.model, state}
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

  def handle_cast({:complete_user_task, task_name, return_data}, state) do
    state =
      if Enum.find(state.task_instances, fn t_i -> t_i.name == task_name end) do
        data = Map.merge(state.data, return_data)
        state = Map.put(state, :data, data)

        task_instances =
          Enum.reject(state.task_instances, fn task -> task.name == task_name end)

        state = Map.put(state, :task_instances, task_instances)

        task_def = get_task_def(task_name, state)

        state =
          if task_def.next, do: process_next_task(state, task_def.next, task_def.name), else: state

        execute_process(state)
      else
        state
      end

    {:noreply, state}
  end

  def handle_cast({:notify_child_complete, sub_process_name, child_data}, state) do
    task_instance =
      Enum.find(state.task_instances, fn ti -> ti.sub_process == sub_process_name end)

    task_instance = Map.put(task_instance, :complete, true)

    task_instances =
      Enum.map(state.task_instances, fn ti ->
        if ti.name == task_instance.name, do: task_instance, else: ti
      end)

    state =
      state |> Map.put(:task_instances, task_instances) |> Map.put(:data, child_data)

    state = execute_process(state)
    {:noreply, state}
  end

  def handle_cast({:set_model, model}, state) do
    {:noreply, Map.put(state, :model, model)}
  end

  def handle_cast({:set_data, data}, state) do
    {:noreply, Map.put(state, :data, data)}
  end

  ## callback utilities

  defp complete_service_task(task, state) do
    data = task.function.(state.data)
    state = Map.put(state, :data, data)

    task_instances =
      Enum.reject(state.task_instances, fn task_i -> task_i.name == task.name end)

    state = Map.put(state, :task_instances, task_instances)

    state = if task.next, do: process_next_task(state, task.next, task.name), else: state
    execute_process(state)
  end

  defp complete_parallel_task_i(task_i, state) do
    task_instances =
      Enum.reject(state.task_instances, fn ti -> ti.name == task_i.name end)

    state = Map.put(state, :task_instances, task_instances)

    next_states = task_i.multi_next

    state = process_next_task_list(state, next_states, task_i.name)

    execute_process(state)
  end

  defp complete_joint_task(task_i, state) do
    task_instances =
      Enum.reject(state.task_instances, fn ti -> ti.name == task_i.name end)

    state = Map.put(state, :task_instances, task_instances)

    state = process_next_task(state, task_i.next, task_i.name)

    execute_process(state)
  end

  defp complete_choice_task(task, state) do
    next_task_name =
      Enum.find_value(
        task.choices,
        fn choice -> if choice.expression.(state.data), do: choice.next end
      )

    state = process_next_task(state, next_task_name, task.name)

    task_instances =
      Enum.reject(state.task_instances, fn task_i -> task_i.name == task.name end)

    state = Map.put(state, :task_instances, task_instances)
    execute_process(state)
  end

  defp complete_subprocess_task_i(task_i, state) do
    data = Map.merge(task_i.data, state.data)
    state = Map.put(state, :data, data)

    task_instances =
      Enum.reject(state.task_instances, fn ti -> task_i.name == ti.name end)

    state = Map.put(state, :task_instances, task_instances)

    state = if task_i.next, do: process_next_task(state, task_i.next, task_i.name), else: state
    execute_process(state)
  end

  defp get_task_def(task_name, state) do
    Enum.find(state.model.tasks, fn task -> task.name == task_name end)
  end

  defp get_complete_able_task(state) do
    Enum.find(state.task_instances, fn ti -> Task.complete_able(ti) end)
  end

  defp work_remaining(state) do
    state.task_instances != []
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
      ## process is complete
      if state.parent do
        ProcessEngine.notify_child_complete(state.parent, state.model.name, state.data)
      end

      Map.put(state, :complete, true)
    end
  end
end
