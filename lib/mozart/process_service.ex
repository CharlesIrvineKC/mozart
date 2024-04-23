defmodule Mozart.ProcessService do
  use GenServer

  alias Mozart.UserService
  alias Mozart.UserTaskService

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

  ## Callbacks

  def init(_init_arg) do
    {:ok, %{process_instances: %{}}}
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
    member_groups = UserService.get_assigned_groups(user_id)
    tasks = UserTaskService.get_tasks_for_groups(member_groups)
    {:reply, tasks, state}
  end

  def handle_cast({:register_process_instance, uid, pid}, state) do
    process_instances = Map.put(state.process_instances, uid, pid)
    {:noreply, Map.put(state, :process_instances, process_instances)}
  end
end
