defmodule Mozart.ProcessManager do
  use GenServer

  alias Mozart.ProcessEngine

  ## Client API

  def start_link(_init_arg) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  ## Callbacks

  def init(_init_arg) do
    {:ok, %{process_instances: %{}, process_models: %{}}}
  end

  def handle_call(:ping, _from, state) do
    {:reply, :pong, state}
  end

  def handle_call({:get_process_model, name}, _from, state) do
    process_models = state.process_models
    process_model = Map.get(process_models, name)
    {:reply, process_model, state}
  end

  def handle_call({:start_process, process_model_name, data}, _from, state) do
    process_model = Map.get(state.process_models, process_model_name)
    {:ok, process_pid} = GenServer.start_link(ProcessEngine, {process_model, data})
    process_id = GenServer.call(process_pid, :get_id)
    process_instances = Map.put(state.process_instances, process_id, process_pid)
    {:reply, process_id, Map.put(state, :process_instances, process_instances)}
  end

  def handle_cast({:load_process_model, process_model}, state) do
    process_models = Map.put(state.process_models, process_model.name, process_model)
    {:noreply, Map.put(state, :process_models, process_models)}
  end
end
