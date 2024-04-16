defmodule Mozart.UserService do
  use GenServer

  ## Client API

  def start_link(_init_arg) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def get_assigned_groups(user_name) do
    GenServer.call(__MODULE__, {:get_assigned_groups, user_name})
  end

  def insert_user(user) do
    GenServer.cast(__MODULE__, {:insert_user, user})
  end

  def get_user(user_name) do
    GenServer.call(__MODULE__, {:get_user, user_name})
  end

  ## Callbacks

  def init(_init_arg) do
    {:ok, %{users: []}}
  end

  def handle_call({:get_user, user_name}, _from, state) do
    user = Enum.find(state.users, fn user -> user.name == user_name end)
    {:reply, user, state}
  end

  def handle_call({:get_assigned_groups, user_name}, _from, state) do
    user = Enum.find(state.users, fn user -> user.name == user_name end)
    {:reply, user.groups, state}
  end

  def handle_cast({:insert_user, user}, state) do
    users = [user | state.users]
    new_state = Map.put(state, :users, users)
    {:noreply, new_state}
  end
end
