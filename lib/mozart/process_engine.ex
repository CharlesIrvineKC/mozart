defmodule Mozart.ProcessEngine do
  use GenServer

  alias Mozart.Data.ProcessState
  alias Ecto.UUID

  ## Client API

  def start_link(model, data) do
    GenServer.start_link(__MODULE__, {model, data})
  end

  def get_state(ppid) do
    GenServer.call(ppid, :get_state)
  end

  def get_id(ppid) do
    GenServer.call(ppid, :get_id)
  end

  def get_data(ppid) do
    GenServer.call(ppid, :get_data)
  end

  def get_open_tasks(ppid) do
    GenServer.call(ppid, :get_open_tasks)
  end

  def complete_user_task(ppid, task_id, data) do
    GenServer.cast(ppid, {:complete_user_task, task_id, data})
  end

  def set_data(ppid, data) do
    GenServer.cast(ppid, {:set_data, data})
  end

  ## GenServer callbacks

  def init({model, data}) do
    id = UUID.generate()
    state = %ProcessState{model: model, data: data, id: id}
    state = Map.put(state, :open_task_names, [state.model.initial_task])
    state = execute_process(state)
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

  def handle_cast({:complete_user_task, task_name, return_data}, state) do
    state =
      if Enum.member?(state.open_task_names, task_name) do
        data = Map.merge(state.data, return_data)
        state = Map.put(state, :data, data)
        open_task_names = List.delete(state.open_task_names, task_name)
        state = Map.put(state, :open_task_names, open_task_names)
        execute_process(state)
      else
        state
      end

    {:noreply, state}
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

    execute_process(state)
  end

  def get_task(task_name, state) do
    Enum.find(state.model.tasks, fn task -> task.name == task_name end)
  end

  def execute_process(state) do
    open_tasks = Enum.map(state.open_task_names, fn name -> get_task(name, state) end)
    service_tasks = Enum.filter(open_tasks, fn task -> task.type == :service end)

    if service_tasks != [] do
      complete_service_task(List.first(service_tasks), state)
    else
      state
    end
  end
end
