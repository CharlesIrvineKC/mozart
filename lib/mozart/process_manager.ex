defmodule Mozart.ProcessManager do
  use GenServer

  alias Mozart.ProcessEngine
  alias Mozart.UserManager

  ## Client API

  def start_link(_init_arg) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def get_process_model(model_name) do
    GenServer.call(__MODULE__, {:get_process_model, model_name})
  end

  def get_process_ppid(process_id) do
    GenServer.call(__MODULE__, {:get_process_ppid, process_id})
  end

  def start_process(model_name, process_data) do
    GenServer.call(__MODULE__, {:start_process, model_name, process_data})
  end

  def get_user_tasks(user_id) do
    GenServer.call(__MODULE__, {:get_user_tasks, user_id})
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

  def handle_call({:get_process_ppid, process_id}, _from, state) do
    {:reply, Map.get(state.process_instances, process_id), state}
  end

  def handle_call({:start_process, process_model_name, data}, _from, state) do
    process_model = Map.get(state.process_models, process_model_name)
    {:ok, process_pid} = GenServer.start_link(ProcessEngine, {process_model, data})
    process_id = GenServer.call(process_pid, :get_id)
    process_instances = Map.put(state.process_instances, process_id, process_pid)
    {:reply, process_id, Map.put(state, :process_instances, process_instances)}
  end

  def handle_call({:get_user_tasks, user_id}, _from, state) do
    member_groups = UserManager.get_assigned_groups(user_id)
    tasks = find_tasks_assigned_to_groups(member_groups, state.process_instances)
    {:reply, tasks, state}
  end

  def find_tasks_assigned_to_groups(_groups, _p_instances) do
    []
  end

  def handle_cast({:load_process_model, process_model}, state) do
    process_models = Map.put(state.process_models, process_model.name, process_model)
    {:noreply, Map.put(state, :process_models, process_models)}
  end
end
