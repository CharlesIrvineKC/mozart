defmodule Mozart.ProcessService do
  use GenServer

  alias Mozart.ProcessModelService
  alias Mozart.ProcessEngine
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

  def start_process(model_name, process_data) do
    GenServer.call(__MODULE__, {:start_process, model_name, process_data})
  end

  def start_sub_process(model_name, process_data, parent_uid) do
    GenServer.cast(__MODULE__, {:start_sub_process, model_name, process_data, parent_uid})
  end

  def get_user_tasks(user_id) do
    GenServer.call(__MODULE__, {:get_user_tasks, user_id})
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

  def handle_call({:start_process, process_model_name, data}, _from, state) do
    process_model = ProcessModelService.get_process_model(process_model_name)
    {:ok, process_pid} = ProcessEngine.start_link(process_model, data)
    process_uid = ProcessEngine.get_uid(process_pid)
    process_instances = Map.put(state.process_instances, process_uid, process_pid)
    {:reply, process_uid, Map.put(state, :process_instances, process_instances)}
  end

  def handle_cast({:start_sub_process, process_model_name, data, parent_uid}, state) do
    process_model = ProcessModelService.get_process_model(process_model_name)
    {:ok, process_pid} = ProcessEngine.start_link(process_model, data, parent_uid)
    process_uid = ProcessEngine.get_uid(process_pid)
    process_instances = Map.put(state.process_instances, process_uid, process_pid)
    {:noreply, Map.put(state, :process_instances, process_instances)}
  end
end
