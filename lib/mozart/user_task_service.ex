defmodule Mozart.UserTaskService do
  use GenServer

  ## Client API

  def start_link(_init_arg) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def get_user_tasks() do
    GenServer.call(__MODULE__, :get_user_tasks)
  end

  def insert_user_task(task) do
    GenServer.cast(__MODULE__, {:insert_user_task, task})
  end

  # def complete_user_task(task) do
  #   GenServer.cast(__MODULE__, {:complete_user_task, task})
  # end

  def get_tasks_for_groups(groups) do
    GenServer.call(__MODULE__, {:get_tasks_for_groups, groups})
  end

  def clear_user_tasks() do
    GenServer.cast(__MODULE__, :clear_user_tasks)
  end

  ## Callbacks

  def init(_init_arg) do
    {:ok, %{user_tasks: %{}}}
  end

  def handle_call(:get_user_tasks, _from, state) do
    {:reply, state.user_tasks, state}
  end

  def handle_call({:get_tasks_for_groups, groups}, _from, state) do
    intersection = fn grp1, grp2 ->
      temp = grp1 -- grp2
      grp1 -- temp
    end

    tasks =
      Enum.filter(Map.values(state.user_tasks), fn task ->
        intersection.(task.assigned_groups, groups) != []
      end)

    {:reply, tasks, state}
  end

  # def handle_cast({:complete_user_task, task}, state) do

  # end

  def handle_cast(:clear_user_tasks, _state) do
    {:noreply, %{user_tasks: %{}}}
  end

  def handle_cast({:insert_user_task, task}, state) do
    user_tasks = Map.put(state.user_tasks, task.uid, task)
    state = Map.put(state, :user_tasks, user_tasks)
    {:noreply, state}
  end
end
