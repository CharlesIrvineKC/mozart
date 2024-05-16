defmodule Mozart.ProcessService do
  use GenServer

  alias Mozart.ProcessEngine, as: PE
  alias Mozart.UserService, as: US

  require Logger

  ## Client API

  def start_link(_init_arg) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def get_cached_state(uid) do
    GenServer.call(__MODULE__, {:get_cached_state, uid})
  end

  def get_completed_process(uid) do
    GenServer.call(__MODULE__, {:get_completed_process, uid})
  end

  def get_process_instances() do
    GenServer.call(__MODULE__, :get_process_instances)
  end

  def get_process_ppid(process_uid) do
    GenServer.call(__MODULE__, {:get_process_ppid, process_uid})
  end

  def get_user_tasks() do
    GenServer.call(__MODULE__, :get_user_tasks)
  end

  def get_user_tasks(user_id) do
    GenServer.call(__MODULE__, {:get_user_tasks, user_id})
  end

  def register_process_instance(uid, pid) do
    GenServer.cast(__MODULE__, {:register_process_instance, uid, pid})
  end

  def process_completed_process_instance(process_state) do
    GenServer.cast(__MODULE__, {:process_completed_process_instance, process_state})
  end

  def get_state() do
    GenServer.call(__MODULE__, :get_state)
  end

  def complete_user_task(ppid, user_task, data) do
    GenServer.cast(__MODULE__, {:complete_user_task, ppid, user_task, data})
  end

  def assign_user_task(task_i, user_id) do
    GenServer.cast(__MODULE__, {:assign_user_task, task_i, user_id})
  end

  def insert_user_task(task) do
    GenServer.cast(__MODULE__, {:insert_user_task, task})
  end

  def clear_user_tasks() do
    GenServer.cast(__MODULE__, :clear_user_tasks)
  end

  def cache_pe_state(uid, pe_state) do
    GenServer.call(__MODULE__, {:cache_pe_state, uid, pe_state})
  end

  ## Callbacks

  def init(_init_arg) do
    initial_state = %{
      process_instances: %{},
      user_tasks: %{},
      completed_processes: %{},
      restart_state_cache: %{}
    }

    Logger.info("Process service initialized")

    {:ok, initial_state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:get_process_instances, _from, state) do
    {:reply, state.process_instances, state}
  end

  def handle_call({:get_process_ppid, process_uid}, _from, state) do
    {:reply, Map.get(state.process_instances, process_uid), state}
  end

  def handle_call({:get_completed_process, uid}, _from, state) do
    {:reply, Map.get(state.completed_processes, uid), state}
  end

  def handle_call({:get_user_tasks, user_id}, _from, state) do
    member_groups = US.get_assigned_groups(user_id)
    tasks = get_tasks_for_groups(member_groups, state)
    {:reply, tasks, state}
  end

  def handle_call(:get_user_tasks, _from, state) do
    {:reply, state.user_tasks, state}
  end

  def handle_call({:get_cached_state, uid}, _from, state) do
    {pe_state, new_cache} = Map.pop(state.restart_state_cache, uid)
    state = if pe_state, do: Map.put(state, :restart_state_cache, new_cache), else: state
    {:reply, pe_state, state}
  end

  def handle_call({:cache_pe_state, uid, pe_state}, _from, state) do
    state = Map.put(state, :restart_state_cache, Map.put(state.restart_state_cache, uid, pe_state))
    {:reply, pe_state, state}
  end

  def handle_cast({:register_process_instance, uid, pid}, state) do
    process_instances = Map.put(state.process_instances, uid, pid)
    {:noreply, Map.put(state, :process_instances, process_instances)}
  end

  def handle_cast({:process_completed_process_instance, pe_state}, state) do
    pid = Map.get(state.process_instances, pe_state.uid)

    state =
      Map.put(
        state,
        :completed_processes,
        Map.put(state.completed_processes, pe_state.uid, pe_state)
      )

    state =
      Map.put(state, :process_instances, Map.delete(state.process_instances, pe_state.uid))

    Process.exit(pid, :shutdown)

    {:noreply, state}
  end

  def handle_cast({:complete_user_task, ppid, user_task_uid, data}, state) do
    Map.put(state, :user_tasks, Map.delete(state.user_tasks, user_task_uid))
    PE.complete_user_task(ppid, user_task_uid, data)
    {:noreply, state}
  end

  def handle_cast({:assign_user_task, task_i, user_id}, state) do
    task_i = Map.put(task_i, :assignee, user_id)
    state = Map.put(state, :user_tasks, Map.put(state.user_tasks, task_i.uid, task_i))
    {:noreply, state}
  end

  def handle_cast(:clear_user_tasks, state) do
    {:noreply, Map.put(state, :user_tasks, %{})}
  end

  def handle_cast({:insert_user_task, task}, state) do
    user_tasks = Map.put(state.user_tasks, task.uid, task)
    state = Map.put(state, :user_tasks, user_tasks)
    {:noreply, state}
  end

  def get_tasks_for_groups(groups, state) do
    intersection = fn grp1, grp2 ->
      temp = grp1 -- grp2
      grp1 -- temp
    end

    Enum.filter(Map.values(state.user_tasks), fn task ->
      intersection.(task.assigned_groups, groups) != []
    end)
  end
end
