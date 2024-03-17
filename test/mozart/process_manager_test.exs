defmodule Mozart.ProcessManagerTest do
  alias Mozart.ProcessManager
  use ExUnit.Case

  test "start process manager" do
    assert GenServer.call(ProcessManager, :ping) == :pong
  end
end
