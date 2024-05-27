defmodule Mozart.ProcessModelService do
  @moduledoc """
  Acts as a reposatory for storing and retreiving `Mozart.Data.ProcessModel`
  """

  @doc false
  use GenServer

  ## Client API

  @doc false
  def start_link(_init_arg) do
    {:ok, _pid} = GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @doc """
  Loads a list of `Mozart.Data.ProcessModel`s into the state of the
  ProcessModelService.
  """
  def load_process_models(models) do
    GenServer.call(__MODULE__, {:load_process_models, models})
  end

  @doc """
  Retrieves a process model by name.
  """
  def get_process_model(model_name) do
    GenServer.call(__MODULE__, {:get_process_model, model_name})
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
  def get_state() do
    GenServer.call(__MODULE__, :get_state)
  end

  @doc false
  def clear_state() do
    GenServer.call(__MODULE__, :clear_state)
  end

  ## GenServer Callbacks

  @doc false
  def init(_init_arg) do
    {:ok, %{process_models: %{}}}
  end

  @doc false
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @doc false
  def handle_call(:clear_state, _from, state) do
    state = Map.put(state, :process_models, %{})
    {:reply, state, state}
  end

  @doc false
  def handle_call({:load_process_models, models}, _from, state) do
    model_list = Enum.map(models, fn m -> {m.name, m} end)
    model_map = Enum.into(model_list, %{}, fn {key, value} -> {key, value} end)
    updated_models = Map.merge(state.process_models, model_map)
    {:reply, updated_models, Map.put(state, :process_models, updated_models)}
  end

  @doc false
  def handle_call({:get_process_model, name}, _from, state) do
    {:reply, Map.get(state.process_models, name), state}
  end

  @doc false
  def handle_call({:load_process_model, process_model}, _from, state) do
    process_models = Map.put(state.process_models, process_model.name, process_model)
    state = Map.put(state, :process_models, process_models)
    {:reply, state, state}
  end

  @doc false
  def handle_call({:clear_then_load_process_models, models}, _from, state) do
    process_models = Enum.map(models, fn model -> {model.name, model} end)
    models = Enum.into(process_models, %{}, fn {key, value} -> {key, value} end)
    {:reply, models, Map.put(state, :process_models, models)}
  end
end
