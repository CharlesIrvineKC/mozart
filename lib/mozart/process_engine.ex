defmodule Mozart.ProcessEngine do
  use GenServer

  alias Mozart.Data.ProcessState
  alias Ecto.UUID

  ## GenServer callbacks

  def init({model, data}) do
    id = UUID.generate()
    state = %ProcessState{model: model, data: data, id: id}
    state = Map.put(state, :open_task_names, [state.model.initial_task])
    state = execute_service_tasks(state)
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

  def handle_call(:get_open_tasks, _from, state) do
    {:reply, state.open_task_names, state}
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

  def complete_service_task(task, state) do
    data = task.function.(state.data)
    Map.put(state, :data, data)
  end

  def get_task(task_name, state) do
    Enum.find(state.model.tasks, fn task -> task.name == task_name end)
  end

  def execute_service_tasks(state) do
    open_tasks = Enum.map(state.open_task_names, fn name -> get_task(name, state) end)
    [service_task] = Enum.filter(open_tasks, fn task -> task.type == :service end)
    complete_service_task(service_task, state)
  end
end
