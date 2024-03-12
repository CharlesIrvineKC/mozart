defmodule Mozart.ProcessEngine do
  use GenServer

  alias Mozart.Data.ProcessState
  alias Ecto.UUID

  ## GenServer callbacks

  def init(state) do
    id = UUID.generate()
    state = Map.put(state, :id, id)
    {:ok, state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:get_model, _from, state) do
    {:reply, state.model, state}
  end

  def handle_call(:get_id, _from, state) do
    {:reply, state.id, state}
  end

  def handle_call(:get_data, _from, state) do
    {:reply, state.data, state}
  end

  def handle_cast({:set_model, model}, state) do
    {:noreply, Map.put(state, :model, model)}
  end

  def handle_cast({:set_data, data}, state) do
    {:noreply, Map.put(state, :data, data)}
  end

  def handle_cast({:complete_task, _task}, state) do
    {:noreply, state}
  end

  ## callback utilities

  def initialize_tasks(state) do
    %{model: model} = state
    %{initial_task: task, tasks: tasks} = model
    tasks = [task | tasks]
    model = Map.put(model, :tasks, tasks)
    Map.put(state, :model, model)
  end

  def complete_service_task(_task, _state) do

  end

  def execute_service_tasks(state) do
    %ProcessState{open_tasks: open_tasks, data: _data} = state
    service_tasks = Enum.filter(open_tasks, fn task -> task.type == :service end)
    Enum.each(service_tasks, fn task -> complete_service_task(task, state) end)
  end
end
