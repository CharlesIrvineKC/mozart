defmodule Mozart.UserManager do
  use GenServer

  ## Client API

  def start_link(_init_arg) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def get_assigned_groups(user_id) do
    GenServer.call(__MODULE__, {:get_assigned_groups, user_id})
  end

  ## Callbacks

  def init(init_arg) do
    {:ok, init_arg}
  end

  def handle_call({:get_assigned_groups, _user_id}, _from, state) do
    {:reply, [:admin], state}
  end
end
