defmodule Mozart.ProcessService do
  use GenServer

  alias Mozart.ProcessEngine
  alias Mozart.UserService
  alias Mozart.UserTaskService

  ## Client API

  def start_link(_init_arg) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def get_process_model(model_name) do
    GenServer.call(__MODULE__, {:get_process_model, model_name})
  end

  def get_process_ppid(process_uid) do
    GenServer.call(__MODULE__, {:get_process_ppid, process_uid})
  end

  def start_process(model_name, process_data) do
    GenServer.call(__MODULE__, {:start_process, model_name, process_data})
  end

  def get_user_tasks(user_id) do
    GenServer.call(__MODULE__, {:get_user_tasks, user_id})
  end

  def load_process_model(model) do
    GenServer.cast(__MODULE__, {:load_process_model, model})
  end

  ## Callbacks

  def init(_init_arg) do
    {:ok, %{process_instances: %{}, process_models: %{}}}
  end

  def handle_call({:get_process_model, name}, _from, state) do
    process_models = state.process_models
    process_model = Map.get(process_models, name)
    {:reply, process_model, state}
  end

  def handle_call({:get_process_ppid, process_uid}, _from, state) do
    {:reply, Map.get(state.process_instances, process_uid), state}
  end

  def handle_call({:start_process, process_model_name, data}, _from, state) do
    process_model = Map.get(state.process_models, process_model_name)
    {:ok, process_pid} = GenServer.start_link(ProcessEngine, {process_model, data})
    process_uid = GenServer.call(process_pid, :get_id)
    process_instances = Map.put(state.process_instances, process_uid, process_pid)
    {:reply, process_uid, Map.put(state, :process_instances, process_instances)}
  end

  def handle_call({:get_user_tasks, user_id}, _from, state) do
    member_groups = UserService.get_assigned_groups(user_id)
    tasks = UserTaskService.get_tasks_for_groups(member_groups)
    {:reply, tasks, state}
  end

  def handle_cast({:load_process_model, process_model}, state) do
    process_models = Map.put(state.process_models, process_model.name, process_model)
    {:noreply, Map.put(state, :process_models, process_models)}
  end
end
