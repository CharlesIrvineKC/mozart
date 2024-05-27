defmodule Mozart.UserService do
  @moduledoc """
  Provides client applications with functionality related to users and groups. Much more
  functionality to come.
  """
  use GenServer

  ## Client API

  @doc false
  def start_link(_init_arg) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @doc """
  Returns the groups that a user is a member of.
  """
  def get_assigned_groups(user_name) do
    GenServer.call(__MODULE__, {:get_assigned_groups, user_name})
  end

  @doc """
  Adds a new user to the system.
  """
  def insert_user(user) do
    GenServer.cast(__MODULE__, {:insert_user, user})
  end

  @doc """
  Given a user id, return detailed user info.
  """
  def get_user(user_name) do
    GenServer.call(__MODULE__, {:get_user, user_name})
  end

  ## Callbacks

  @doc false
  def init(_init_arg) do
    {:ok, %{users: []}}
  end

  @doc false
  def handle_call({:get_user, user_name}, _from, state) do
    user = Enum.find(state.users, fn user -> user.name == user_name end)
    {:reply, user, state}
  end

  @doc false
  def handle_call({:get_assigned_groups, user_name}, _from, state) do
    user = Enum.find(state.users, fn user -> user.name == user_name end)
    {:reply, user.groups, state}
  end

  @doc false
  def handle_cast({:insert_user, user}, state) do
    users = [user | state.users]
    new_state = Map.put(state, :users, users)
    {:noreply, new_state}
  end
end
