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

  def handle_call({:complete_user_task, task_name, return_data}, _from, state) do
    state =
      if Enum.member?(state.open_task_names, task_name) do
        data = Map.merge(state.data, return_data)
        state = Map.put(state, :data, data)
        open_task_names = List.delete(state.open_task_names, task_name)
        state = Map.put(state, :open_task_names, open_task_names)
        execute_service_tasks(state)
      else
        state
      end

    {:reply, state.data, state}
  end

  def handle_cast({:set_model, model}, state) do
    {:noreply, Map.put(state, :model, model)}
  end

  def handle_cast({:set_data, data}, state) do
    {:noreply, Map.put(state, :data, data)}
  end

  ## callback utilities

  def complete_service_task(task, state) do
    data = task.function.(state.data)
    state = Map.put(state, :data, data)
    [_ | open_task_names] = state.open_task_names
    state = Map.put(state, :open_task_names, open_task_names)

    state =
      if task.next != nil do
        open_task_names = [task.next | state.open_task_names]
        Map.put(state, :open_task_names, open_task_names)
      else
        state
      end

    execute_service_tasks(state)
  end

  def get_task(task_name, state) do
    Enum.find(state.model.tasks, fn task -> task.name == task_name end)
  end

  def execute_service_tasks(state) do
    open_tasks = Enum.map(state.open_task_names, fn name -> get_task(name, state) end)
    service_tasks = Enum.filter(open_tasks, fn task -> task.type == :service end)

    if service_tasks != [] do
      complete_service_task(List.first(service_tasks), state)
    else
      state
    end
  end
end
