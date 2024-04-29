defmodule Mozart.ProcessModelService do
  use GenServer

  ## Client API

  def start_link(_init_arg) do
    {:ok, _pid} = GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def get_process_model(model_name) do
    GenServer.call(__MODULE__, {:get_process_model, model_name})
  end

  def load_process_model(model) do
    GenServer.cast(__MODULE__, {:load_process_model, model})
  end

  def clear_then_load_process_models(models) do
    GenServer.cast(__MODULE__, {:clear_then_load_process_models, models})
  end

  ## GenServer Callbacks

  def init(_init_arg) do
    {:ok, %{process_models: %{}}}
  end

  def handle_call({:get_process_model, name}, _from, state) do
    process_models = state.process_models
    process_model = Map.get(process_models, name)
    {:reply, process_model, state}
  end

  def handle_cast({:load_process_model, process_model}, state) do
    process_models = Map.put(state.process_models, process_model.name, process_model)
    {:noreply, Map.put(state, :process_models, process_models)}
  end

  def handle_cast({:clear_then_load_process_models, models}, state) do
    process_models = Enum.map(models, fn model -> {model.name, model} end)
    models = Enum.into(process_models, %{}, fn {key, value} -> {key, value} end)
    {:noreply, Map.put(state, :process_models, models)}
  end
end
