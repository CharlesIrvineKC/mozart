defmodule Mozart.ProcessEngine do
  use GenServer

  require Logger

  alias Mozart.ProcessService, as: PS
  alias Mozart.ProcessModelService, as: PMS
  alias Mozart.Data.ProcessState
  alias Phoenix.PubSub
  alias Ecto.UUID

  ## Client API

  def start_link(uid, model_name, data, parent \\ nil) do
    {:ok, pid} = GenServer.start_link(__MODULE__, {uid, model_name, data, parent})
    {:ok, pid, uid}
  end

  def execute(ppid) do
    GenServer.cast(ppid, :execute)
  end

  def execute_and_wait(ppid) do
    GenServer.call(ppid, :execute)
  end

  def start_process(model_name, data, parent \\ nil) do
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
    GenServer.call(ppid, {:complete_user_task, task_uid, data})
  end

  def complete_user_task_and_go(ppid, task_uid, data) do
    GenServer.cast(ppid, {:complete_user_task, task_uid, data})
  end

  def set_data(ppid, data) do
    GenServer.cast(ppid, {:set_data, data})
  end

  def is_complete(ppid) do
    GenServer.call(ppid, :is_complete)
  end

  def notify_child_complete(parent_pid, sub_process_name, data, completed_tasks) do
    GenServer.call(parent_pid, {:notify_child_complete, sub_process_name, data, completed_tasks})
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
          parent: parent,
          start_time: DateTime.utc_now()
        }

    PS.register_process_instance(uid, self())

    Phoenix.PubSub.subscribe(:pubsub, "pe_topic")

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

  def handle_call({:complete_user_task, task_uid, return_data}, _from, state) do
    state = complete_user_task_impl(state, task_uid, return_data)
    {:reply, state, state}
  end

  def handle_call(:execute, _from, state) do
    model = PMS.get_process_model(state.model_name)
    state = create_next_tasks(state, model.initial_task)
    state = execute_process(state)
    {:reply, state, state}
  end

  def handle_call({:notify_child_complete, sp_name, c_data, c_completed_tasks}, _from, state) do
    {_uid, task_instance} =
      Enum.find(state.task_instances, fn {_uid, ti} -> ti.sub_process == sp_name end)

    task_instance = Map.put(task_instance, :complete, true)
    task_instances = Map.put(state.task_instances, task_instance.uid, task_instance)
    completed_tasks = state.completed_tasks ++ c_completed_tasks

    state
    |> Map.put(:task_instances, task_instances)
    |> Map.put(:data, c_data)
    |> Map.put(:completed_tasks, completed_tasks)
    |> execute_process()

    {:reply, state, state}
  end

  defp complete_user_task_impl(state, task_uid, return_data) do
    task_instance = get_task_instance(task_uid, state)

    if task_instance do
      data = Map.merge(state.data, return_data)
      state = Map.put(state, :data, data)

      state = update_for_completed_task(state, task_instance)

      state =
        if task_instance.next,
          do: create_next_tasks(state, task_instance.next, task_instance.name),
          else: state

      Logger.info("Complete user task [#{task_instance.name}][#{task_instance.uid}]")
      execute_process(state)
    else
      state
    end
  end

  def handle_cast({:complete_user_task, task_uid, return_data}, state) do
    state = complete_user_task_impl(state, task_uid, return_data)
    {:noreply, state}
  end

  def handle_cast(:execute, state) do
    model = PMS.get_process_model(state.model_name)
    state = create_next_tasks(state, model.initial_task)
    state = execute_process(state)
    {:noreply, state}
  end

  def handle_cast({:set_data, data}, state) do
    {:noreply, Map.put(state, :data, data)}
  end

  def handle_info({:timer_expired, timer_task_uid}, state) do
    timer_task = Map.get(state.task_instances, timer_task_uid)
    timer_task = Map.put(timer_task, :expired, true)

    state =
      Map.put(state, :task_instances, Map.put(state.task_instances, timer_task_uid, timer_task))

    state = execute_process(state)
    {:noreply, state}
  end

  def handle_info({:message, payload}, state) do
    task_instances =
      Enum.into(state.task_instances, %{}, fn {uid, task} ->
        if task.type == :receive do
          {uid, update_receive_event_task(task, payload)}
        else
          {uid, task}
        end
      end)

    state = Map.put(state, :task_instances, task_instances)

    state = execute_process(state)
    {:noreply, state}
  end

  def terminate(reason, state) do
    {reason_code, _} = reason

    if reason_code != :shutdown do
      IO.puts("Process engine terminated with reason:")
      IO.inspect(reason, label: "terminate reason")
      IO.inspect(state, label: "terminate state")

      PS.cache_pe_state(state.uid, state)
    end

    # Process.sleep(50)
  end

  ## callback utilities

  defp update_receive_event_task(s_task, payload) do
    select_result = s_task.message_selector.(payload)

    if select_result do
      Map.put(s_task, :data, select_result)
      |> Map.put(:complete, true)
    else
      s_task
    end
  end

  defp set_timer_for(task_uid, timer_duration) do
    self = self()
    spawn(fn -> wait_and_notify(self, task_uid, timer_duration) end)
  end

  defp wait_and_notify(parent_pe, task_uid, timer_duration) do
    Process.sleep(timer_duration)
    send(parent_pe, {:timer_expired, task_uid})
  end

  defp create_new_next_task(state, next_task_name, previous_task_name) do
    new_task_i = get_new_task_instance(next_task_name, state)

    new_task_i =
      if new_task_i.type == :join do
        Map.put(new_task_i, :inputs, List.delete(new_task_i.inputs, previous_task_name))
      else
        new_task_i
      end

    state =
      Map.put(state, :task_instances, Map.put(state.task_instances, new_task_i.uid, new_task_i))

    if new_task_i.type == :timer, do: set_timer_for(new_task_i.uid, new_task_i.timer_duration)

    if new_task_i.type == :user, do: PS.insert_user_task(new_task_i)

    if new_task_i.type == :send,
      do: PubSub.broadcast(:pubsub, "pe_topic", {:message, new_task_i.message})

    if new_task_i.type == :sub_process do
      data = state.data
      {:ok, process_pid, _uid} = start_process(new_task_i.sub_process, data, self())
      execute(process_pid)
    else
      state
    end

    Logger.info("New task instance [#{new_task_i.name}][#{new_task_i.uid}]")

    state
  end

  def create_next_tasks(state, next_task_name, previous_task_name \\ nil) do
    existing_task = get_existing_task_instance(state, next_task_name)

    if existing_task && existing_task.type == :join do
      process_existing_join_next_task(state, existing_task, previous_task_name)
    else
      create_new_next_task(state, next_task_name, previous_task_name)
    end
  end

  defp process_next_task_list(state, [], _parent_name) do
    state
  end

  defp process_next_task_list(state, [task_name | rest], parent_name) do
    state = create_next_tasks(state, task_name, parent_name)
    process_next_task_list(state, rest, parent_name)
  end

  defp get_existing_task_instance(state, task_name) do
    result =
      Enum.find(state.task_instances, fn {_uid, task} -> task.name == task_name end)

    if result,
      do:
        (
          {_uid, task_instance} = result
          task_instance
        )
  end

  defp process_existing_join_next_task(state, existing_task, previous_task_name) do
    ## delete previous task name from inputs
    existing_task =
      Map.put(
        existing_task,
        :inputs,
        List.delete(existing_task.inputs, previous_task_name)
      )

    ## Update existing task instance in state
    Map.put(
      state,
      :task_instances,
      Map.put(state.task_instances, existing_task.uid, existing_task)
    )
  end

  defp update_for_completed_task(state, task) do
    task_instances = Map.delete(state.task_instances, task.uid)
    completed_tasks = [task | state.completed_tasks]

    state
    |> Map.put(:task_instances, task_instances)
    |> Map.put(:completed_tasks, completed_tasks)
  end

  defp update_task_state(state, task) do
    state = update_for_completed_task(state, task)
    if task.next, do: create_next_tasks(state, task.next, task.name), else: state
  end

  defp complete_send_event_task(state, task) do
    Logger.info("Complete send event task [#{task.name}[#{task.uid}]")
    update_task_state(state, task) |> execute_process()
  end

  defp complete_join_task(state, task) do
    Logger.info("Complete join task [#{task.name}]")
    update_task_state(state, task) |> execute_process()
  end

  defp complete_timer_task(state, task) do
    Logger.info("Complete timer task [#{task.name}]")
    update_task_state(state, task) |> execute_process()
  end

  defp complete_service_task(state, task) do
    Logger.info("Complete service task [#{task.name}[#{task.uid}]")
    data = task.function.(state.data)
    Map.put(state, :data, data) |> update_task_state(task) |> execute_process()
  end

  defp complete_decision_task(state, task) do
    Logger.info("Complete decision task [#{task.name}[#{task.uid}]")
    data = Map.merge(state.data, Tablex.decide(task.tablex, state.data[task.decision_args]))
    Map.put(state, :data, data) |> update_task_state(task) |> execute_process()
  end

  defp complete_parallel_task_i(state, task) do
    Logger.info("Complete parallel task [#{task.name}]")
    next_states = task.multi_next

    update_for_completed_task(state, task)
    |> process_next_task_list(next_states, task.name)
    |> execute_process()
  end

  defp complete_receive_event_task(state, task) do
    Logger.info("Complete receive event task [#{task.name}]")

    Map.put(state, :data, Map.merge(state.data, task.data))
    |> update_task_state(task)
    |> execute_process()
  end

  defp complete_choice_task(state, task) do
    Logger.info("Complete choice task [#{task.name}][#{task.uid}]")

    next_task_name =
      Enum.find_value(
        task.choices,
        fn choice -> if choice.expression.(state.data), do: choice.next end
      )

    state
    |> create_next_tasks(next_task_name, task.name)
    |> update_task_state(task)
    |> execute_process()
  end

  defp complete_subprocess_task_i(state, task) do
    Logger.info("Complete subprocess task [#{task.name}][#{task.uid}]")
    data = Map.merge(task.data, state.data)
    Map.put(state, :data, data) |> update_task_state(task) |> execute_process()
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
    result = Enum.find(state.task_instances, fn {_uid, task} -> complete_able(task) end)

    if result do
      {_uid, task} = result
      task
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
            complete_service_task(state, complete_able_task_i)

          complete_able_task_i.type == :choice ->
            complete_choice_task(state, complete_able_task_i)

          complete_able_task_i.type == :sub_process ->
            complete_subprocess_task_i(state, complete_able_task_i)

          complete_able_task_i.type == :parallel ->
            complete_parallel_task_i(state, complete_able_task_i)

          complete_able_task_i.type == :join ->
            complete_join_task(state, complete_able_task_i)

          complete_able_task_i.type == :timer ->
            complete_timer_task(state, complete_able_task_i)

          complete_able_task_i.type == :receive ->
            complete_receive_event_task(state, complete_able_task_i)

          complete_able_task_i.type == :send ->
            complete_send_event_task(state, complete_able_task_i)

          complete_able_task_i.type == :decision ->
            complete_decision_task(state, complete_able_task_i)
        end
      else
        state
      end
    else
      ## no work remaining so process is complete
      # if process instance has a parent process
      if state.parent do
        notify_child_complete(state.parent, state.model_name, state.data, state.completed_tasks)
      end

      now = DateTime.utc_now()

      state =
        Map.put(state, :complete, true)
        |> Map.put(:end_time, now)
        |> Map.put(:execute_duration, DateTime.diff(now, state.start_time, :microsecond))

      Logger.info("Process complete [#{state.model_name}][#{state.uid}]")

      PS.process_completed_process_instance(state)
      state
    end
  end

  defp complete_able(t) when t.type == :decision, do: true
  defp complete_able(t) when t.type == :service, do: true
  defp complete_able(t) when t.type == :send, do: true
  defp complete_able(t) when t.type == :receive, do: t.complete
  defp complete_able(t) when t.type == :send, do: true
  defp complete_able(t) when t.type == :timer, do: t.expired
  defp complete_able(t) when t.type == :parallel, do: true
  defp complete_able(t) when t.type == :choice, do: true
  defp complete_able(t) when t.type == :sub_process, do: t.complete
  defp complete_able(t) when t.type == :join, do: t.inputs == []
  defp complete_able(t) when t.type == :user, do: t.complete
end
