defmodule Mozart.ProcessEngine do
  @moduledoc """
  A ProcessEngine is dynamically spawned for the purpose of executing a process model defined by **defprocess** function call.
  """

  @doc false
  use GenServer

  require Logger

  alias Mozart.ProcessService, as: PS
  alias Mozart.Data.ProcessState
  alias Mozart.Data.ExecutionFrame
  alias Phoenix.PubSub
  alias Ecto.UUID
  alias Mozart.Task

  ## Client API

  @doc false
  def start_link(uid, process, data, business_key) do
    {:ok, pid} = GenServer.start_link(__MODULE__, {uid, process, data, business_key})

    {:ok, pid, {uid, business_key}}
  end

  @doc """
  Used to complete any "complete-able" open tasks. Task execution frequently spawns new
  open tasks. Execute will continue to called recursively as long as there are "complete-able" open tasks.
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
  engine will start executing tasks when the execute/1 function is called.

  Arguments are a process model name, initial process data, an optional business_key, and a parent
  process pid if there is a parent. If a process key is not specified, one will be assigned.

  Returns a tuple of the form:
  ```
  {:ok, ppid, uid, business_key}
  ```
  where:
  * **ppid** is the Elixir pid for the spawned GenServer.
  * **uid** is a uniquie identifier for a process execution.
  * **business_key** is a unique identifier for a hierarchial process execution.

  Sample invocation:
  ```
  {:ok, ppid, uid, business_key} = ProcessEngine.start_process("a process model name", )
  ```
  """

  def start_process(process, data, business_key \\ nil) do
    uid = UUID.generate()
    business_key = business_key || UUID.generate()

    child_spec = %{
      id: MyProcessEngine,
      start: {Mozart.ProcessEngine, :start_link, [uid, process, data, business_key]},
      restart: :transient
    }

    {:ok, pid, {uid, business_key}} =
      DynamicSupervisor.start_child(ProcessEngineSupervisor, child_spec)

    {:ok, pid, uid, business_key}
  end

  @doc false
  def restart_process(state) do
    uid = state.uid
    process = state.top_level_process
    data = state.data
    business_key = state.business_key

    child_spec = %{
      id: MyProcessEngine,
      start: {Mozart.ProcessEngine, :start_link, [uid, process, data, business_key]},
      restart: :transient
    }

    {:ok, pid, {uid, business_key}} =
      DynamicSupervisor.start_child(ProcessEngineSupervisor, child_spec)

    {:ok, pid, uid, business_key}
  end

  @doc false
  def complete_on_task_exit_event(ppid) do
    GenServer.cast(ppid, :complete_on_task_exit_event)
  end

  def get_completed_tasks(ppid) do
    GenServer.call(ppid, :get_completed_tasks)
  end

  @doc """
  Returns the state of the process. Useful for debugging.
  """
  def get_state(ppid) do
    GenServer.call(ppid, :get_state)
  end

  @doc false
  def restore_previous_state(ppid, previous_state) do
    GenServer.call(ppid, {:restore_previous_state, previous_state})
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
  Gets the open tasks of the given process engine. Useful for debugging.
  """
  def get_open_tasks(ppid) do
    GenServer.call(ppid, :get_open_tasks)
  end

  @doc false
  def get_all_open_tasks(ppid) do
    GenServer.call(ppid, :get_all_open_tasks)
  end

  @doc false
  def complete_user_task(ppid, task_uid, data) do
    GenServer.call(ppid, {:complete_user_task, task_uid, data})
  end

  @doc false
  def assign_user_task(ppid, task_uid, user_id) do
    GenServer.cast(ppid, {:assign_user_task, task_uid, user_id})
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
  def init({uid, process, data, business_key}) do
    pe_recovered_state = PS.get_cached_state(uid)

    state =
      pe_recovered_state ||
        %ProcessState{
          uid: uid,
          data: data,
          business_key: business_key,
          top_level_process: process,
          start_time: DateTime.utc_now(),
          execution_frames: [%ExecutionFrame{process: process, data: data}]
        }

    # if pe_recovered_state do
    #   Logger.warning("Restart process instance [#{process}][#{uid}]")
    # else
    #   Logger.info("Start process instance [#{process}][#{uid}]")
    # end

    Logger.info("Start process instance [#{process}][#{uid}]")

    {:ok, state, {:continue, {:register_and_subscribe, uid}}}
  end

  @doc false
  def handle_continue({:register_and_subscribe, uid}, state) do
    PS.register_process_instance(uid, self(), state.business_key)
    Phoenix.PubSub.subscribe(:pubsub, "pe_topic")
    {:noreply, state}
  end

  def handle_call({:restore_previous_state, previous_state}, _from, state) do
    state =
      state
      |> Map.put(:execution_frames, previous_state.execution_frames)
      |> Map.put(:completed_tasks, previous_state.completed_tasks)

    {:reply, state, state}
  end

  def handle_call(:is_complete, _from, state) do
    {:reply, state.complete, state}
  end

  def handle_call(:get_all_open_tasks, _from, state) do
    open_tasks = get_all_open_tasks_impl(state)
    {:reply, open_tasks, state}
  end

  def handle_call(:get_completed_tasks, _from, state) do
    {:reply, state.completed_tasks, state}
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
    {:reply, get_open_tasks_impl(state), state}
  end

  def handle_call({:complete_user_task, task_uid, return_data}, _from, state) do
    state = complete_user_task_impl(state, task_uid, return_data)
    {:reply, state, state}
  end

  def handle_call(:execute, _from, state) do
    model = PS.get_process_model(get_process_from_state(state))
    state = create_next_tasks(state, model.initial_task)
    state = execute_process(state)
    {:reply, state, state}
  end

  def handle_cast(:complete_on_task_exit_event, state) do
    Process.sleep(200)
    now = DateTime.utc_now()

    state =
      Map.put(state, :complete, :exit_on_task_event)
      |> Map.put(:end_time, now)
      |> Map.put(:execute_duration, DateTime.diff(now, state.start_time, :microsecond))

    PS.update_for_completed_process(state)

    Logger.info(
      "Exit process: complete due to task exit event [#{get_process_from_state(state)}][#{state.uid}]"
    )

    Process.exit(self(), :shutdown)
    {:noreply, state}
  end

  def handle_cast(:execute, state) do
    current_state = get_current_execution_frame(state)
    model = PS.get_process_model(current_state.process)

    state = create_next_tasks(state, model.initial_task) |> execute_process()
    {:noreply, state}
  end

  def handle_cast({:notify_child_complete, subprocess_name, subprocess_data}, state) do
    subprocess_task =
      Enum.find_value(get_open_tasks_impl(state), fn {_uid, t} ->
        if t.type == :subprocess && t.process == subprocess_name, do: t
      end)

    subprocess_task = Map.put(subprocess_task, :complete, true)
    open_tasks = Map.put(get_open_tasks_impl(state), subprocess_task.uid, subprocess_task)

    state =
      state
      |> Map.put(:open_tasks, open_tasks)
      |> Map.put(:data, subprocess_data)
      |> execute_process()

    {:noreply, state}
  end

  def handle_cast({:complete_user_task, task_uid, return_data}, state) do
    state = complete_user_task_impl(state, task_uid, return_data)
    {:noreply, state}
  end

  def handle_cast({:assign_user_task, task_uid, user_id}, state) do
    task_instance = get_task_instance(task_uid, state)
    task_instance = Map.put(task_instance, :assigned_user, user_id)
    state = insert_open_task(state, task_instance)
    {:noreply, state}
  end

  def handle_cast({:set_data, data}, state) do
    {:noreply, Map.put(state, :data, data)}
  end

  def handle_info({:timer_expired, timer_task_uid}, state) do
    timer_task = Map.get(get_open_tasks_impl(state), timer_task_uid)
    timer_task = Map.put(timer_task, :expired, true)

    state = insert_open_task(state, timer_task)

    state = execute_process(state)
    {:noreply, state}
  end

  def handle_info({:message, payload}, state) do
    open_tasks =
      Enum.into(get_open_tasks_impl(state), %{}, fn {uid, task} ->
        if task.type == :receive,
          do: {uid, update_receive_event_task(task, payload)},
          else: {uid, task}
      end)

    state = set_open_tasks(state, open_tasks)

    state = execute_process(state)
    {:noreply, state}
  end

  def handle_info({:exit_task_event, payload}, state) do
    model = PS.get_process_model(get_process_from_state(state))
    event = Enum.find(model.events, fn e -> apply(e.module, e.selector, [payload]) end)
    state = if event, do: exit_task(event, state), else: state
    {:noreply, state}
  end

  defp set_open_tasks(state, tasks) do
    execution_frame = hd(state.execution_frames)
    execution_frame = Map.put(execution_frame, :open_tasks, tasks)
    Map.put(state, :execution_frames, [execution_frame | tl(state.execution_frames)])
  end

  defp exit_task(event, state) do
    open_tasks = Map.values(get_open_tasks_impl(state))
    task = Enum.find(open_tasks, fn t -> t.name == event.exit_task end)
    task = Map.put(task, :complete, :exit_on_task_event)

    if task.type == :subprocess, do: complete_on_task_exit_event(task.subprocess_pid)

    # TODO: Code exit repeat task

    update_completed_task_state(state, task, event.next) |> execute_process()
  end

  def terminate(reason, state) do
    {reason_code, _} = reason

    if reason_code != :shutdown do
      IO.puts("Process engine terminated with reason:")
      IO.puts("terminate reason: #{inspect(reason)}")
      IO.puts("terminate state: #{inspect(state)}")

      PS.cache_pe_state(state.uid, state)
    end
  end

  ## callback utilities

  defp update_receive_event_task(s_task, payload) do
    select_result = apply(s_task.module, s_task.selector, [payload])

    if select_result,
      do: Map.put(s_task, :data, select_result) |> Map.put(:complete, true),
      else: s_task
  end

  defp set_timer_for(timer_task, timer_duration) do
    apply(timer_task.module, timer_task.function, [
      timer_task.uid,
      timer_task.process_uid,
      timer_duration
    ])
  end

  defp insert_open_task(state, task) do
    execution_frame = get_current_execution_frame(state)
    open_tasks = execution_frame.open_tasks |> Map.put(task.uid, task)
    execution_frame = Map.put(execution_frame, :open_tasks, open_tasks)

    Map.put(state, :execution_frames, [execution_frame | tl(state.execution_frames)])
  end

  defp update_user_task(new_task, state) do
    input_data =
      if new_task.inputs,
        do: Map.take(state.data, new_task.inputs),
        else: state.data

    new_task =
      if new_task.listener,
        do: apply(new_task.module, new_task.listener, [new_task, input_data]),
        else: new_task

    new_task = Map.put(new_task, :data, input_data)|> Map.put(:business_key, state.business_key)

    PS.insert_user_task(new_task)

    new_task
  end

  defp trigger_repeat_execution(state, new_task) do
    if apply(new_task.module, new_task.condition, [state.data]) do
      first_task = get_new_task_instance(new_task.first, state)
      process_new_task(state, first_task, new_task.name)
    else
      new_task = Map.put(new_task, :complete, true)
      insert_open_task(state, new_task)
    end
  end

  defp create_new_next_task(state, next_task_name, previous_task_name) do
    new_task = get_new_task_instance(next_task_name, state)
    process_new_task(state, new_task, previous_task_name)
  end

  defp process_new_task(state, new_task, previous_task_name) do
    Logger.info("New #{new_task.type} task instance [#{new_task.name}][#{new_task.uid}]")

    new_task =
      if new_task.type == :join do
        Map.put(new_task, :inputs, List.delete(new_task.inputs, previous_task_name))
      else
        new_task
      end

    if new_task.type == :timer, do: set_timer_for(new_task, new_task.timer_duration)

    if new_task.type == :send,
      do: PubSub.broadcast(:pubsub, "pe_topic", {:message, new_task.message})

    new_task =
      if new_task.type == :user, do: update_user_task(new_task, state), else: new_task

    state = insert_open_task(state, new_task)

    state =
      if new_task.type == :repeat,
        do: trigger_repeat_execution(state, new_task),
        else: state

    state =
      if new_task.type == :conditional,
        do: trigger_conditional_execution(state, new_task),
        else: state

    if new_task.type == :subprocess, do: spawn_subprocess_task(new_task, state), else: state
  end

  defp get_task_def(task_name, process_name) do
    model = PS.get_process_model(process_name)
    get_task_def_from_model(task_name, model)
  end

  defp get_task_def_from_model(task_name, model) do
    Enum.find(model.tasks, fn task -> task.name == task_name end)
  end

  defp get_new_task_instance(task_name, state) do
    process_name = get_process_from_state(state)
    get_task_def(task_name, process_name) |> initialize_new_task(state.uid)
  end

  defp initialize_new_task(task, process_uid) do
    task
    |> Map.put(:uid, Ecto.UUID.generate())
    |> Map.put(:start_time, DateTime.utc_now())
    |> Map.put(:process_uid, process_uid)
  end

  defp spawn_subprocess_task(new_subprocess_task, state) do
    # get initial subprocess task
    process_name = new_subprocess_task.process
    model = PS.get_process_model(process_name)
    initial_task_name = model.initial_task
    initial_task = get_task_def_from_model(initial_task_name, model)
    initial_task = initialize_new_task(initial_task, state.uid)

    initial_task =
      if initial_task.type == :user, do: update_user_task(initial_task, state), else: initial_task

    Logger.info(
      "New #{initial_task.type} task instance [#{initial_task.name}][#{initial_task.uid}]"
    )

    new_execution_frame = %ExecutionFrame{
      process: new_subprocess_task.process,
      data: state.data,
      parent_task_uid: new_subprocess_task.uid,
      open_tasks: %{initial_task.uid => initial_task}
    }

    state = Map.put(state, :execution_frames, [new_execution_frame | state.execution_frames])

    state =
      if initial_task.type == :conditional,
        do: trigger_conditional_execution(state, initial_task),
        else: state

    state =
      if initial_task.type == :repeat,
        do: trigger_repeat_execution(state, initial_task),
        else: state

    state
  end

  defp trigger_conditional_execution(state, new_task) do
    if apply(new_task.module, new_task.condition, [state.data]) do
      first_task = get_new_task_instance(new_task.first, state)
      process_new_task(state, first_task, new_task.name)
    else
      new_task = Map.put(new_task, :complete, true)
      insert_open_task(state, new_task)
    end
  end

  defp get_current_execution_frame(state) do
    state.execution_frames |> hd()
  end

  def create_next_tasks(state, next_task_name, previous_task_name \\ nil) do
    existing_task = get_existing_task_instance(state, next_task_name)

    state =
      if existing_task && existing_task.type == :join do
        process_existing_join_next_task(state, existing_task, previous_task_name)
      else
        create_new_next_task(state, next_task_name, previous_task_name)
      end

    state
  end

  def process_next_task_list(state, [], _parent_name) do
    state
  end

  def process_next_task_list(state, [task_name | rest], parent_name) do
    state = create_next_tasks(state, task_name, parent_name)
    process_next_task_list(state, rest, parent_name)
  end

  defp get_open_tasks_impl(state) do
    get_current_execution_frame(state) |> Map.get(:open_tasks)
  end

  defp get_all_open_tasks_impl(state) do
    Enum.map(state.execution_frames, fn ex_state -> Map.values(ex_state.open_tasks) end)
    |> List.flatten()
  end

  defp get_existing_task_instance(state, task_name) do
    Enum.find_value(get_open_tasks_impl(state), fn {_uid, task} ->
      if task.name == task_name, do: task
    end)
  end

  defp process_existing_join_next_task(state, existing_task, previous_task_name) do
    ## delete previous task name from inputs
    existing_task =
      Map.put(existing_task, :inputs, List.delete(existing_task.inputs, previous_task_name))

    ## Update existing task instance in state
    insert_open_task(state, existing_task)
  end

  def update_for_completed_task(state, task) do
    now = DateTime.utc_now()
    duration = DateTime.diff(now, task.start_time, :microsecond)

    task =
      task
      |> Map.put(:finish_time, now)
      |> Map.put(:duration, duration)

    execution_frames = delete_open_task_from_execution_frame(task, state)

    completed_tasks = state.completed_tasks ++ [task]

    state
    |> Map.put(:completed_tasks, completed_tasks)
    |> Map.put(:execution_frames, execution_frames)
    |> check_for_repeat_task_completion(task)
    |> check_for_conditional_task_completion(task)
  end

  defp delete_open_task_from_execution_frame(task, state) do
    execution_frame = hd(state.execution_frames)
    open_tasks = execution_frame.open_tasks
    open_task = Enum.find_value(open_tasks, fn {_k, t} -> if t.name == task.name, do: t end)

    if open_task do
      open_tasks = Map.delete(open_tasks, open_task.uid)
      execution_frame = Map.put(execution_frame, :open_tasks, open_tasks)
      [execution_frame | tl(state.execution_frames)]
    else
      state.execution_frames
    end
  end

  defp check_for_repeat_task_completion(state, task) do
    r_task = find_repeat_task_by_last_task(state, task.name)
    if r_task, do: trigger_repeat_execution(state, r_task), else: state
  end

  defp check_for_conditional_task_completion(state, task) do
    c_task = find_conditional_task_by_last_task(state, task.name)

    if c_task do
      c_task = Map.put(c_task, :complete, true)
      insert_open_task(state, c_task)
    else
      state
    end
  end

  defp find_repeat_task_by_last_task(state, task_name) do
    Enum.find_value(get_open_tasks_impl(state), fn {_key, t} ->
      if t.type == :repeat && t.last == task_name, do: t
    end)
  end

  defp find_conditional_task_by_last_task(state, task_name) do
    Enum.find_value(get_open_tasks_impl(state), fn {_key, t} ->
      if t.type == :conditional && t.last == task_name, do: t
    end)
  end

  def update_completed_task_state(state, task, next_task) do
    state = update_for_completed_task(state, task)
    if next_task, do: create_next_tasks(state, next_task, task.name), else: state
  end

  def get_process_from_state(state) do
    current_state = get_current_execution_frame(state)
    current_state.process
  end

  def get_task_instance(task_uid, state), do: Map.get(get_open_tasks_impl(state), task_uid)

  defp get_complete_able_task(state) do
    Enum.find_value(get_open_tasks_impl(state), fn {_uid, task} ->
      if Task.completable(task), do: task
    end)
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
    get_open_tasks_impl(state) != %{}
  end

  def execute_process(state) do
    if work_remaining(state) do
      complete_able_task = get_complete_able_task(state)

      if complete_able_task do
        Task.complete_task(complete_able_task, state)
      else
        PS.persist_process_state(state)
        state
      end
    else
      # No work remaining.
      Logger.info(
        "Exit process: process complete [#{get_process_from_state(state)}][#{state.uid}]"
      )

      now = DateTime.utc_now()
      state =
        Map.put(state, :complete, true)
        |> Map.put(:end_time, now)
        |> Map.put(:execute_duration, DateTime.diff(now, state.start_time, :microsecond))

      if tl(state.execution_frames) == [] do
        # This is the top level process, so exit process
        PS.update_for_completed_process(state)
        PS.delete_process_state(state)
        Process.exit(self(), :shutdown)
      else
        update_execution_frame_stack(state) |> execute_process()
      end
    end
  end

  defp update_execution_frame_stack(state) do
    new_execution_frames = tl(state.execution_frames)
    completed_execution_frame = hd(state.execution_frames)

    new_current_execution_frame = hd(new_execution_frames)

    completing_task_open_tasks = new_current_execution_frame.open_tasks

    spawning_task_uid = completed_execution_frame.parent_task_uid
    completing_task = Map.get(completing_task_open_tasks, spawning_task_uid)
    completing_task = Map.put(completing_task, :complete, true)

    completing_task_open_tasks =
      Map.put(completing_task_open_tasks, completing_task.uid, completing_task)

    new_current_execution_frame =
      Map.put(new_current_execution_frame, :open_tasks, completing_task_open_tasks)

    Map.put(state, :execution_frames, [new_current_execution_frame | tl(new_execution_frames)])
  end
end
