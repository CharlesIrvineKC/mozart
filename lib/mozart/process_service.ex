defmodule Mozart.ProcessService do
  @moduledoc """
  This modeule provides a set of utility services.
  """

  @doc false
  use GenServer

  alias Mozart.ProcessEngine, as: PE
  alias Mozart.UserService, as: US

  require Logger

  ## Client API

  @doc false
  def start_link(_init_arg) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @doc false
  def persist_process_state(pe_state) do
    GenServer.cast(__MODULE__, {:persist_process_state, pe_state})
  end

  @doc false
  def get_persisted_process_state(pe_uid) do
    GenServer.call(__MODULE__, {:get_persisted_process_state, pe_uid})
  end

  @doc """
  Get active process instances
  """
  def get_active_processes() do
    GenServer.call(__MODULE__, :get_active_processes)
  end

  @doc false
  def get_cached_state(uid) do
    GenServer.call(__MODULE__, {:get_cached_state, uid})
  end

  @doc false
  def get_processes_for_business_key(business_key) do
    GenServer.call(__MODULE__, {:get_processes_for_business_key, business_key})
  end

  @doc """
  Returns the state of the completed process corresponding to the process engine's uid
  """
  def get_completed_process(uid) do
    GenServer.call(__MODULE__, {:get_completed_process, uid})
  end

  @doc """
  Returns the data accumulated by the completed process
  """
  def get_completed_process_data(uid) do
    GenServer.call(__MODULE__, {:get_completed_process_data, uid})
  end

  @doc false
  def get_process_pid_from_uid(uid) do
    GenServer.call(__MODULE__, {:get_process_pid_from_uid, uid})
  end

  @doc """
  Returns the user tasks that can be completed by users belonging to one of the input groups.
  """
  def get_user_tasks_for_groups(groups) do
    GenServer.call(__MODULE__, {:get_user_tasks_for_groups, groups})
  end

  @doc false
  def update_for_completed_process(process_state) do
    GenServer.call(__MODULE__, {:update_for_completed_process, process_state})
  end

  @doc false
  def get_user_task(uid) do
    GenServer.call(__MODULE__, {:get_user_task, uid})
  end

  @doc false
  def get_completed_processes() do
    GenServer.call(__MODULE__, :get_completed_processes)
  end

  @doc false
  def get_process_ppid(process_uid) do
    GenServer.call(__MODULE__, {:get_process_ppid, process_uid})
  end

  @doc false
  def get_user_tasks() do
    GenServer.call(__MODULE__, :get_user_tasks)
  end

  @doc """
  Get user tasks eligible for assignment and completion by the specified user.
  """
  def get_user_tasks_for_user(user_id) do
    GenServer.call(__MODULE__, {:get_user_tasks_for_user, user_id})
  end

  @doc false
  def register_process_instance(uid, pid, business_key) do
    GenServer.cast(__MODULE__, {:register_process_instance, uid, pid, business_key})
  end

  @doc false
  def process_completed_process_instance(process_state) do
    GenServer.call(__MODULE__, {:process_completed_process_instance, process_state})
  end

  @doc false
  def get_state() do
    GenServer.call(__MODULE__, :get_state)
  end

  @doc """
  Completes a user task.
  """
  def complete_user_task(user_task_uid, data) do
    GenServer.cast(__MODULE__, {:complete_user_task, user_task_uid, data})
  end

  @doc false
  def assign_user_task(task, user_id) do
    GenServer.cast(__MODULE__, {:assign_user_task, task, user_id})
  end

  @doc false
  def insert_user_task(task) do
    GenServer.cast(__MODULE__, {:insert_user_task, task})
  end

  @doc false
  def clear_user_tasks() do
    GenServer.cast(__MODULE__, :clear_user_tasks)
  end

  @doc false
  def clear_state() do
    GenServer.call(__MODULE__, :clear_state)
  end

  @doc false
  def cache_pe_state(uid, pe_state) do
    GenServer.call(__MODULE__, {:cache_pe_state, uid, pe_state})
  end

  @doc """
  Loads a list of process model into the state of the
  ProcessService.
  """
  def load_process_models(models) do
    GenServer.call(__MODULE__, {:load_process_models, models})
  end

  @doc """
  Loads a BPM Application
  """
  def load_bpm_application(bpm_application) do
    GenServer.call(__MODULE__, {:load_bpm_application, bpm_application})
  end

  @doc """
  Gets a BPM Application
  """
  def get_bpm_application(app_name) do
    GenServer.call(__MODULE__, {:get_bpm_application, app_name})
  end

  @doc """
  Gets the names of all BPM applications
  """
  def get_bpm_applications do
    GenServer.call(__MODULE__, :get_bpm_applications)
  end

  @doc """
  Retrieves a process model by name.
  """
  def get_process_model(model_name) do
    GenServer.call(__MODULE__, {:get_process_model, model_name})
  end

  @doc false
  def get_process_models do
    GenServer.call(__MODULE__, :get_process_models)
  end

  @doc """
  Loads a single process model in the repository.
  """
  def load_process_model(model) do
    GenServer.call(__MODULE__, {:load_process_model, model})
  end

  @doc false
  def clear_then_load_process_models(models) do
    GenServer.call(__MODULE__, {:clear_then_load_process_models, models})
  end

  @doc false
  def get_process_model_db() do
    GenServer.call(__MODULE__, :get_process_model_db)
  end

  @doc false
  def get_completed_process_db() do
    GenServer.call(__MODULE__, :get_completed_process_db)
  end

  @doc false
  def get_user_task_db() do
    GenServer.call(__MODULE__, :get_user_task_db)
  end

  ## Callbacks

  @doc false
  def init(_init_arg) do
    {:ok, user_task_db} = CubDB.start_link(data_dir: "database/user_task_db")
    {:ok, completed_process_db} = CubDB.start_link(data_dir: "database/completed_process_db")
    {:ok, process_model_db} = CubDB.start_link(data_dir: "database/process_model_db")
    {:ok, bpm_application_db} = CubDB.start_link(data_dir: "database/bpm_application_db")
    {:ok, process_state_db} = CubDB.start_link(data_dir: "database/process_state_db")

    initial_state = %{
      active_process_groups: %{},
      active_processes: %{},
      restart_state_cache: %{},
      user_task_db: user_task_db,
      completed_process_db: completed_process_db,
      process_model_db: process_model_db,
      bpm_application_db: bpm_application_db,
      process_state_db: process_state_db
    }

    Logger.info("Process service initialized")

    {:ok, initial_state, {:continue, :restart_persisted_processes}}
  end

  def handle_continue(:restart_persisted_processes, state) do
    restart_persisted_processes(state)
    {:noreply, state}
  end

  def handle_call({:get_processes_for_business_key, business_key}, _from, state) do
    process_group = Map.get(state.active_process_groups, business_key)
    process_pids = Map.values(process_group)
    process_states = Enum.map(process_pids, fn pid -> PE.get_state(pid) end)
    {:reply, process_states, state}
  end

  def handle_call(:get_process_model_db, _from, state) do
    {:reply, state.process_model_db, state}
  end

  def handle_call(:get_user_task_db, _from, state) do
    {:reply, state.user_task_db, state}
  end

  def handle_call(:get_completed_process_db, _from, state) do
    {:reply, state.completed_process_db, state}
  end

  @doc false
  def handle_call(:clear_state, _from, state) do
    CubDB.clear(state.user_task_db)
    CubDB.clear(state.completed_process_db)
    CubDB.clear(state.process_model_db)
    CubDB.clear(state.bpm_application_db)

    new_state = %{
      active_processes: %{},
      active_process_groups: %{},
      restart_state_cache: %{},
      user_task_db: state.user_task_db,
      completed_process_db: state.completed_process_db,
      process_model_db: state.process_model_db,
      bpm_application_db: state.bpm_application_db,
      process_state_db: state.process_state_db
    }

    {:reply, new_state, new_state}
  end

  def handle_call(:get_active_processes, _from, state) do
    {:reply, state.active_processes, state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:get_completed_processes, _from, state) do
    {:reply, get_completed_processes_local(state), state}
  end

  def handle_call({:get_process_pid_from_uid, uid}, _from, state) do
    {:reply, Map.get(state.active_processes, uid), state}
  end

  def handle_call({:get_process_ppid, process_uid}, _from, state) do
    {:reply, Map.get(state.active_processes, process_uid), state}
  end

  def handle_call({:get_completed_process, uid}, _from, state) do
    {:reply, CubDB.get(state.completed_process_db, uid), state}
  end

  def handle_call({:get_completed_process_data, uid}, _from, state) do
    completed_process = CubDB.get(state.completed_process_db, uid)
    {:reply, completed_process.data, state}
  end

  def handle_call({:get_user_tasks_for_groups, groups}, _from, state) do
    tasks = get_user_tasks_for_groups_local(groups, state)
    {:reply, tasks, state}
  end

  def handle_call({:get_user_tasks_for_user, user_id}, _from, state) do
    member_groups = US.get_assigned_groups(user_id)
    tasks = get_user_tasks_for_groups_local(member_groups, state)
    {:reply, tasks, state}
  end

  def handle_call(:get_user_tasks, _from, state) do
    {:reply, get_user_tasks(state), state}
  end

  def handle_call({:get_user_task, uid}, _from, state) do
    {:reply, get_user_task_by_id(state, uid), state}
  end

  def handle_call({:get_cached_state, uid}, _from, state) do
    {pe_state, new_cache} = Map.pop(state.restart_state_cache, uid)
    state = if pe_state, do: Map.put(state, :restart_state_cache, new_cache), else: state
    {:reply, pe_state, state}
  end

  def handle_call({:cache_pe_state, uid, pe_state}, _from, state) do
    state =
      Map.put(state, :restart_state_cache, Map.put(state.restart_state_cache, uid, pe_state))

    {:reply, pe_state, state}
  end

  def handle_call({:load_bpm_application, bpm_application}, _from, state) do
    CubDB.put(state.bpm_application_db, bpm_application.name, bpm_application)
    {:reply, bpm_application.name, state}
  end

  def handle_call({:get_bpm_application, app_name}, _from, state) do
    app = CubDB.get(state.bpm_application_db, app_name)
    {:reply, app, state}
  end

  def handle_call(:get_bpm_applications, _from, state) do
    apps = CubDB.select(state.bpm_application_db) |> Enum.to_list()
    {:reply, apps, state}
  end

  def handle_call({:load_process_models, models}, _from, state) do
    Enum.each(models, fn m -> CubDB.put(state.process_model_db, m.name, m) end)
    {:reply, {:ok, Enum.map(models, fn m -> m.name end)}, state}
  end

  @doc false
  def handle_call({:get_process_model, name}, _from, state) do
    {:reply, CubDB.get(state.process_model_db, name), state}
  end

  def handle_call(:get_process_models, _from, state) do
    models =
      CubDB.select(state.process_model_db)
      |> Enum.to_list()

    {:reply, models, state}
  end

  @doc false
  def handle_call({:load_process_model, process_model}, _from, state) do
    {:reply, CubDB.put(state.process_model_db, process_model.name, process_model), state}
  end

  @doc false
  def handle_call({:clear_then_load_process_models, models}, _from, state) do
    CubDB.clear(state.process_model_db)
    Enum.each(models, fn m -> CubDB.put(state.process_model_db, m.name, m) end)
    {:reply, models, Map.put(state, :process_models, models)}
  end

  def handle_call({:update_for_completed_process, pe_process}, _from, state) do
    state = Map.put(state, :active_processes, Map.delete(state.active_processes, pe_process.uid))

    state =
      Map.put(
        state,
        :active_process_groups,
        Map.delete(state.active_process_groups, pe_process.business_key)
      )

    CubDB.put(state.completed_process_db, pe_process.uid, pe_process)
    {:reply, pe_process, state}
  end

  def handle_call({:get_persisted_process_state, pe_uid}, _from, state) do
    {:reply, CubDB.get(state.process_state_db, pe_uid), state}
  end

  def handle_cast({:persist_process_state, pe_state}, state) do
    CubDB.put(state.process_state_db, pe_state.uid, pe_state)
    {:noreply, state}
  end

  def handle_cast({:register_process_instance, uid, pid, business_key}, state) do
    active_processes = Map.put(state.active_processes, uid, pid)
    state = Map.put(state, :active_processes, active_processes)
    state = get_active_process_groups(uid, pid, business_key, state)
    {:noreply, state}
  end

  def handle_cast({:complete_user_task, user_task_uid, data}, state) do
    user_task = get_user_task_by_id(state, user_task_uid)
    ppid = Map.get(state.active_processes, user_task.process_uid)
    CubDB.delete(state.user_task_db, user_task_uid)
    PE.complete_user_task_and_go(ppid, user_task_uid, data)
    {:noreply, state}
  end

  def handle_cast({:assign_user_task, task, user_id}, state) do
    task = Map.put(task, :assignee, user_id)
    insert_user_task(state, task)
    {:noreply, state}
  end

  def handle_cast(:clear_user_tasks, state) do
    CubDB.clear(state.user_task_db)
    {:noreply, state}
  end

  def handle_cast({:insert_user_task, task}, state) do
    insert_user_task(state, task)
    {:noreply, state}
  end

  @doc false
  def get_active_process_groups(uid, pid, business_key, state) do
    processes = Map.get(state.active_process_groups, business_key) || %{}
    processes = Map.put(processes, uid, pid)
    active_process_groups = Map.put(state.active_process_groups, business_key, processes)
    Map.put(state, :active_process_groups, active_process_groups)
  end

  defp insert_user_task(state, task) do
    CubDB.put(state.user_task_db, task.uid, task)
  end

  defp get_user_tasks_for_groups_local(groups, state) do
    intersection = fn l1, l2 -> Enum.filter(l2, fn item -> Enum.member?(l1, item) end) end

    CubDB.select(state.user_task_db)
    |> Stream.map(fn {_uid, t} -> t end)
    |> Stream.filter(fn t -> intersection.(groups, t.assigned_groups) end)
    |> Enum.to_list()
  end

  @doc false
  def get_completed_processes_local(state) do
    CubDB.select(state.completed_process_db)
    |> Stream.map(fn {_k, v} -> v end)
    |> Enum.to_list()
  end

  defp get_user_task_by_id(state, uid) do
    CubDB.get(state.user_task_db, uid)
  end

  defp restart_persisted_processes(state) do
    persisted_processes = CubDB.select(state.process_state_db)
    Enum.each(persisted_processes, fn {_uid, pe_state} -> PE.restart_process(pe_state) end)
  end

  defp get_user_tasks(state) do
    CubDB.select(state.user_task_db) |> Stream.map(fn {_k, v} -> v end) |> Enum.to_list()
  end
end
