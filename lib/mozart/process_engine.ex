defmodule Mozart.ProcessEngine do
  use GenServer

  ## GenServer callbacks

  def init(init_arg) do
    {:ok, init_arg}
  end
end
