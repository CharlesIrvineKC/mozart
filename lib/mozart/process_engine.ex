defmodule Mozart.ProcessEngine do
  use GenServer

  alias Mozart.Data.ProcessState
  alias Mozart.UserTaskManager
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

  def is_complete(ppid) do
    GenServer.call(ppid, :is_complete)
  end

  ## GenServer callbacks

  def init({model, data}) do
    id = UUID.generate()
    state = %ProcessState{model: model, data: data, id: id, open_task_names: []}
    state = insert_new_task(state, state.model.initial_task)
    state = execute_process(state)
    {:ok, state}
  end

  def insert_new_task(state, task_name) do
    new_task = get_task(task_name, state)
    if (new_task.type == :user), do: UserTaskManager.insert_user_task(new_task)
    Map.put(state, :open_task_names, [task_name | state.open_task_names])
  end

  def handle_call(:is_complete, _from, state) do
    {:reply, state.complete, state}
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

  defp complete_service_task(task, state) do
    data = task.function.(state.data)
    state = Map.put(state, :data, data)
    [_ | open_task_names] = state.open_task_names
    state = Map.put(state, :open_task_names, open_task_names)

    state =
      if task.next != nil do
        insert_new_task(state, task.next)
      else
        state
      end

    execute_process(state)
  end

  def complete_choice_task(task, state) do
    next_task_name =
      Enum.find_value(
        task.choices,
        fn choice -> if choice.expression.(state.data), do: choice.next end
      )
    state = insert_new_task(state, next_task_name)
    state = Map.put(state, :open_task_names, List.delete(state.open_task_names, task.name))
    execute_process(state)
  end

  defp get_task(task_name, state) do
    Enum.find(state.model.tasks, fn task -> task.name == task_name end)
  end

  def get_executable_task(state) do
    task_name = Enum.find(state.open_task_names, fn name -> is_executable(name, state) end)
    if task_name, do: get_task(task_name, state)
  end

  defp is_executable(name, state) do
    task = get_task(name, state)
    if task.type == :service || task.type == :choice, do: task
  end

  defp execute_process(state) do
    if state.open_task_names != [] do
      executable_task = get_executable_task(state)

      if executable_task do
        cond do
          executable_task.type == :service ->
            complete_service_task(executable_task, state)

          executable_task.type == :choice ->
            complete_choice_task(executable_task, state)
        end
      else
        state
      end
    else
      Map.put(state, :complete, true)
    end
  end
end
