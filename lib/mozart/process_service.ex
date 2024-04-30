defmodule Mozart.ProcessService do
  use GenServer

  alias Mozart.ProcessModelService, as: PMS
  alias Mozart.ProcessEngine, as: PE
  alias Mozart.UserService, as: US

  ## Client API

  def start_link(_init_arg) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def get_process_instances() do
    GenServer.call(__MODULE__, :get_process_instances)
  end

  def get_process_ppid(process_uid) do
    GenServer.call(__MODULE__, {:get_process_ppid, process_uid})
  end

  def get_user_tasks(user_id) do
    GenServer.call(__MODULE__, {:get_user_tasks, user_id})
  end

  def register_process_instance(uid, pid) do
    GenServer.cast(__MODULE__, {:register_process_instance, uid, pid})
  end

  def start_process(model_name, data) do
    GenServer.call(__MODULE__, {:start_process, model_name, data})
  end

  def get_state() do
    GenServer.call(__MODULE__, :get_state)
  end

  def complete_user_task(user_task, data) do
    GenServer.cast(__MODULE__, {:complete_user_task, user_task, data})
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

  ## Callbacks

  def init(_init_arg) do
    {:ok, %{process_instances: %{}, user_tasks: %{}}}
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

  def handle_call({:get_user_tasks, user_id}, _from, state) do
    member_groups = US.get_assigned_groups(user_id)
    tasks = get_tasks_for_groups(member_groups, state)
    {:reply, tasks, state}
  end

  def handle_call({:start_process, model_name, data}, _from, state) do
    model = PMS.get_process_model(model_name)
    {:ok, pid} = PE.start_link(model, data)
    {:reply, pid, state}
  end

  def handle_cast({:register_process_instance, uid, pid}, state) do
    process_instances = Map.put(state.process_instances, uid, pid)
    {:noreply, Map.put(state, :process_instances, process_instances)}
  end

  def handle_cast({:complete_user_task, user_task_uid, data}, state) do
    pid = Map.get(state.process_instances, user_task_uid)
    PE.complete_user_task(pid, user_task_uid, data)
    {:noreply, state}
  end

  def handle_cast({:assign_user_task, task_i, user_id}, state) do
    task_i = Map.put(task_i, :assignee, user_id)
    state = Map.put(state, :user_tasks, Map.put(state.user_tasks, task_i.uid, task_i))
    {:noreply, state}
  end

  def handle_cast(:clear_user_tasks, _state) do
    {:noreply, %{process_instances: %{}, user_tasks: %{}}}
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
