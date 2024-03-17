defmodule Mozart.ProcessManagerTest do
  use ExUnit.Case

  alias Mozart.ProcessManager
  alias Mozart.Util

  test "start process manager" do
    assert GenServer.call(ProcessManager, :ping) == :pong
  end

  test "load a process model" do
    model = Util.get_simple_model()
    GenServer.cast(ProcessManager, {:load_process_model, model})
    model = GenServer.call(ProcessManager, {:get_process_model, :foo})
    assert model.name == :foo
  end
end
