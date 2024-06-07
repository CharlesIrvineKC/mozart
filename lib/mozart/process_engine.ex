defmodule Mozart.ProcessEngine do
  @moduledoc """
  A ProcessEngine is dynamically spawned for the purpose of executing a `Mozart.Data.ProcessModel`.
  """

  @doc false
  use GenServer

  require Logger

  alias Mozart.ProcessService, as: PS
  alias Mozart.Data.ProcessState
  alias Phoenix.PubSub
  alias Ecto.UUID

  ## Client API

  @doc false
  def start_link(uid, model_name, data, parent \\ nil) do
    {:ok, pid} = GenServer.start_link(__MODULE__, {uid, model_name, data, parent})
    {:ok, pid, uid}
  end

  @doc """
  Used to complete any "complete-able" open tasks. Task execution frequently spawns new
  open tasks. Execute will continue to as long as there are "complete-able" open tasks.

  Note: Some types of task are complete-able immediately and some are not. For
  example:
    * A `Mozart.Task.Service` task is complete-able as soon as it is opened.
    * A `Mozart.Task.User` task when a user completes the task.
    * A `Mozart.Task.Receive` task is complete-able when a matching
      `Mozart.Task.Send` task is received.
  """
  def execute(ppid) do
    GenServer.cast(ppid, :execute)
  end

  @doc false
  def execute_and_wait(ppid) do
    GenServer.call(ppid, :execute)
  end

  @doc """
  Use this function to create a ProcessEngine instance initialized with the
  name of the process model to be executed and any initialization data. The
  engine will start executing tasks with the execute/1 function is called.
  """
  def start_process(model_name, data, parent \\ nil) do
    uid = UUID.generate()

    child_spec = %{
      id: MyProcessEngine,
      start: {Mozart.ProcessEngine, :start_link, [uid, model_name, data, parent]},
      restart: :transient
    }

    DynamicSupervisor.start_child(ProcessEngineSupervisor, child_spec)
  end

  @doc """
  Complete subprocess due to a TaskExit event
  """
  def complete_on_task_exit_event(ppid) do
    GenServer.cast(ppid, :complete_on_task_exit_event)
  end

  @doc false
  def get_state(ppid) do
    GenServer.call(ppid, :get_state)
  end

  @doc false
  def get_uid(ppid) do
    GenServer.call(ppid, :get_uid)
  end

  @doc false
  def get_model(ppid) do
    GenServer.call(ppid, :get_model)
  end

  @doc false
  def get_data(ppid) do
    GenServer.call(ppid, :get_data)
  end

  @doc """
  Gets the open tasks of the given process engine
  """
  def get_open_tasks(ppid) do
    GenServer.call(ppid, :get_open_tasks)
  end

  @doc false
  def complete_user_task(ppid, task_uid, data) do
    GenServer.call(ppid, {:complete_user_task, task_uid, data})
  end

  @doc false
  def complete_user_task_and_go(ppid, task_uid, data) do
    GenServer.cast(ppid, {:complete_user_task, task_uid, data})
  end

  @doc false
  def set_data(ppid, data) do
    GenServer.cast(ppid, {:set_data, data})
  end

  @doc false
  def is_complete(ppid) do
    GenServer.call(ppid, :is_complete)
  end

  @doc false
  def notify_child_complete(parent_pid, sub_process_name, data) do
    GenServer.cast(parent_pid, {:notify_child_complete, sub_process_name, data})
  end

  ## GenServer callbacks

  @doc false
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

    if pe_recovered_state do
      Logger.warning("Restart process instance [#{model_name}][#{uid}]")
    else
      Logger.info("Start process instance [#{model_name}][#{uid}]")
    end

    {:ok, state, {:continue, {:register_and_subscribe, uid}}}
  end

  @doc false
  def handle_continue({:register_and_subscribe, uid}, state) do
    PS.register_process_instance(uid, self())
    Phoenix.PubSub.subscribe(:pubsub, "pe_topic")
    {:noreply, state}
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

  def handle_call(:get_open_tasks, _from, state) do
    {:reply, state.open_tasks, state}
  end

  def handle_call({:complete_user_task, task_uid, return_data}, _from, state) do
    state = complete_user_task_impl(state, task_uid, return_data)
    {:reply, state, state}
  end

  def handle_call(:execute, _from, state) do
    model = PS.get_process_model(state.model_name)
    state = create_next_tasks(state, model.initial_task)
    state = execute_process(state)
    {:reply, state, state}
  end

  def handle_cast(:complete_on_task_exit_event, state) do
    now = DateTime.utc_now()

    state =
      Map.put(state, :complete, true)
      |> Map.put(:end_time, now)
      |> Map.put(:execute_duration, DateTime.diff(now, state.start_time, :microsecond))

    Logger.info("Process complete due to task exit even [#{state.model_name}][#{state.uid}]")

    PS.insert_completed_process(state)

    Process.exit(self(), :shutdown)
    {:noreply, state}
  end

  def handle_cast({:notify_child_complete, sp_name, sp_data}, state) do
    {_uid, sp_task} =
      Enum.find(state.open_tasks, fn {_uid, ti} -> ti.sub_process_model_name == sp_name end)

    sp_task = Map.put(sp_task, :complete, true)
    open_tasks = Map.put(state.open_tasks, sp_task.uid, sp_task)

    state
    |> Map.put(:open_tasks, open_tasks)
    |> Map.put(:data, sp_data)
    |> execute_process()

    {:noreply, state}
  end

  def handle_cast({:complete_user_task, task_uid, return_data}, state) do
    state = complete_user_task_impl(state, task_uid, return_data)
    {:noreply, state}
  end

  def handle_cast(:execute, state) do
    model = PS.get_process_model(state.model_name)
    state = create_next_tasks(state, model.initial_task)
    state = execute_process(state)
    {:noreply, state}
  end

  def handle_cast({:set_data, data}, state) do
    {:noreply, Map.put(state, :data, data)}
  end

  def handle_info({:timer_expired, timer_task_uid}, state) do
    timer_task = Map.get(state.open_tasks, timer_task_uid)
    timer_task = Map.put(timer_task, :expired, true)

    state =
      Map.put(state, :open_tasks, Map.put(state.open_tasks, timer_task_uid, timer_task))

    state = execute_process(state)
    {:noreply, state}
  end

  def handle_info({:message, payload}, state) do
    open_tasks =
      Enum.into(state.open_tasks, %{}, fn {uid, task} ->
        if task.type == :receive do
          {uid, update_receive_event_task(task, payload)}
        else
          {uid, task}
        end
      end)

    state = Map.put(state, :open_tasks, open_tasks)

    state = execute_process(state)
    {:noreply, state}
  end

  def handle_info({:event, payload}, state) do
    model = PS.get_process_model(state.model_name)

    if model.events do
      [event] = model.events

      if event.message_selector.(payload) do
        exit_task(event.exit_task, state)
      else
        state
      end
    else
      state
    end

    {:noreply, state}
  end

  defp exit_task(task_name, state) do
    task = Enum.find(Map.values(state.open_tasks), fn t -> t.name == task_name end)

    if task.type == :sub_process do
      complete_on_task_exit_event(task.sub_process_pid)
    end

    Map.put(state, :completed_tasks, [task | state.completed_tasks])
    |> Map.put(:open_tasks, Map.delete(state.open_tasks, task.uid))
    |> execute_process()
  end

  def terminate(reason, state) do
    {reason_code, _} = reason

    if reason_code != :shutdown do
      IO.puts("Process engine terminated with reason:")
      IO.inspect(reason, label: "terminate reason")
      IO.inspect(state, label: "terminate state")

      PS.cache_pe_state(state.uid, state)
    end
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
    new_task = get_new_task_instance(next_task_name, state)
    Logger.info("New task instance [#{new_task.name}][#{new_task.uid}]")

    new_task =
      if new_task.type == :join do
        Map.put(new_task, :inputs, List.delete(new_task.inputs, previous_task_name))
      else
        new_task
      end

    state = do_side_effects(new_task.type, new_task, state)

    if new_task.type != :sub_process do
      Map.put(state, :open_tasks, Map.put(state.open_tasks, new_task.uid, new_task))
    else
      state
    end
  end

  defp do_side_effects(:timer, new_task, state) do
    set_timer_for(new_task.uid, new_task.timer_duration)
    state
  end

  defp do_side_effects(:user, new_task, state) do
    input_data =
      if new_task.input_fields do
        Map.take(state.data, new_task.input_fields)
      else
        state.data
      end

    new_task = Map.put(new_task, :data, input_data)
    PS.insert_user_task(new_task)
    state
  end

  defp do_side_effects(:send, new_task, state) do
    PubSub.broadcast(:pubsub, "pe_topic", {:message, new_task.message})
    state
  end

  defp do_side_effects(:sub_process, new_task, state) do
    data = state.data
    {:ok, process_pid, _uid} = start_process(new_task.sub_process_model_name, data, self())
    execute(process_pid)

    new_task = Map.put(new_task, :sub_process_pid, process_pid)
    open_tasks = Map.put(state.open_tasks, new_task.uid, new_task)
    Map.put(state, :open_tasks, open_tasks)
  end

  defp do_side_effects(_, _, _), do: nil

  defp create_next_tasks(state, next_task_name, previous_task_name \\ nil) do
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
      Enum.find(state.open_tasks, fn {_uid, task} -> task.name == task_name end)

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
      :open_tasks,
      Map.put(state.open_tasks, existing_task.uid, existing_task)
    )
  end

  defp update_for_completed_task(state, task) do
    now = DateTime.utc_now()
    duration = DateTime.diff(now, task.start_time, :microsecond)

    task =
      task
      |> Map.put(:finish_time, now)
      |> Map.put(:duration, duration)

    open_tasks = Map.delete(state.open_tasks, task.uid)
    completed_tasks = [task | state.completed_tasks]

    state
    |> Map.put(:open_tasks, open_tasks)
    |> Map.put(:completed_tasks, completed_tasks)
  end

  defp update_completed_task_state(state, task) do
    state = update_for_completed_task(state, task)
    if task.next, do: create_next_tasks(state, task.next, task.name), else: state
  end

  defp complete_send_event_task(state, task) do
    Logger.info("Complete send event task [#{task.name}[#{task.uid}]")
    update_completed_task_state(state, task) |> execute_process()
  end

  defp complete_join_task(state, task) do
    Logger.info("Complete join task [#{task.name}]")
    update_completed_task_state(state, task) |> execute_process()
  end

  defp complete_timer_task(state, task) do
    Logger.info("Complete timer task [#{task.name}]")
    update_completed_task_state(state, task) |> execute_process()
  end

  defp complete_service_task(state, task) do
    Logger.info("Complete service task [#{task.name}[#{task.uid}]")

    input_data =
      if task.input_fields do
        Map.take(state.data, task.input_fields)
      else
        state.data
      end

    output_data = task.function.(input_data)

    Map.put(state, :data, Map.merge(state.data, output_data))
    |> update_completed_task_state(task)
    |> execute_process()
  end

  defp complete_rule_task(state, task) do
    Logger.info("Complete run task [#{task.name}[#{task.uid}]")
    arguments = Map.take(state.data, task.input_fields) |> Map.to_list()
    data = Map.merge(state.data, Tablex.decide(task.rule_table, arguments))
    Map.put(state, :data, data) |> update_completed_task_state(task) |> execute_process()
  end

  defp complete_parallel_task(state, task) do
    Logger.info("Complete parallel task [#{task.name}]")
    next_states = task.multi_next

    update_for_completed_task(state, task)
    |> process_next_task_list(next_states, task.name)
    |> execute_process()
  end

  defp complete_receive_event_task(state, task) do
    Logger.info("Complete receive event task [#{task.name}]")

    Map.put(state, :data, Map.merge(state.data, task.data))
    |> update_completed_task_state(task)
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
    |> update_completed_task_state(task)
    |> execute_process()
  end

  defp complete_subprocess_task(state, task) do
    Logger.info("Complete subprocess task [#{task.name}][#{task.uid}]")
    data = Map.merge(task.data, state.data)
    Map.put(state, :data, data) |> update_completed_task_state(task) |> execute_process()
  end

  defp get_task_def(task_name, state) do
    model = PS.get_process_model(state.model_name)
    Enum.find(model.tasks, fn task -> task.name == task_name end)
  end

  defp get_task_instance(task_uid, state) do
    Map.get(state.open_tasks, task_uid)
  end

  defp get_new_task_instance(task_name, state) do
    get_task_def(task_name, state)
    |> Map.put(:uid, Ecto.UUID.generate())
    |> Map.put(:start_time, DateTime.utc_now())
    |> Map.put(:process_uid, state.uid)
  end

  defp get_complete_able_task(state) do
    result = Enum.find(state.open_tasks, fn {_uid, task} -> complete_able(task) end)

    if result do
      {_uid, task} = result
      task
    end
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

  defp work_remaining(state) do
    state.open_tasks != %{}
  end

  defp execute_process(state) do
    if work_remaining(state) do
      complete_able_task = get_complete_able_task(state)

      if complete_able_task do
        cond do
          complete_able_task.type == :service ->
            complete_service_task(state, complete_able_task)

          complete_able_task.type == :choice ->
            complete_choice_task(state, complete_able_task)

          complete_able_task.type == :sub_process ->
            complete_subprocess_task(state, complete_able_task)

          complete_able_task.type == :parallel ->
            complete_parallel_task(state, complete_able_task)

          complete_able_task.type == :join ->
            complete_join_task(state, complete_able_task)

          complete_able_task.type == :timer ->
            complete_timer_task(state, complete_able_task)

          complete_able_task.type == :receive ->
            complete_receive_event_task(state, complete_able_task)

          complete_able_task.type == :send ->
            complete_send_event_task(state, complete_able_task)

          complete_able_task.type == :rule ->
            complete_rule_task(state, complete_able_task)
        end
      else
        state
      end
    else
      ## no work remaining so process is complete
      if state.parent do
        notify_child_complete(state.parent, state.model_name, state.data)
      end

      now = DateTime.utc_now()

      state =
        Map.put(state, :complete, true)
        |> Map.put(:end_time, now)
        |> Map.put(:execute_duration, DateTime.diff(now, state.start_time, :microsecond))

      Logger.info("Process complete [#{state.model_name}][#{state.uid}]")

      PS.insert_completed_process(state)

      Process.exit(self(), :shutdown)
      state
    end
  end

  defp complete_able(t) when t.type == :rule, do: true
  defp complete_able(t) when t.type == :run, do: true
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
