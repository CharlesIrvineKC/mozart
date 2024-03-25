defmodule Mozart.ProcessManagerTest do
  use ExUnit.Case

  alias Mozart.ProcessManager
  alias Mozart.ProcessEngine
  alias Mozart.Util

  test "start process manager" do
    assert GenServer.call(ProcessManager, :ping) == :pong
  end

  setup do
    simple_model = Util.get_simple_model()
    GenServer.cast(ProcessManager, {:load_process_model, simple_model})
    simple_data = %{foo: :foo}
    %{ simple_data: simple_data}
  end

  test "load a process model" do
    model = GenServer.call(ProcessManager, {:get_process_model, :foo})
    assert model.name == :foo
  end

  test "start a simple process", %{simple_data: simple_data} do
    simple_model = GenServer.call(ProcessManager, {:get_process_model, :foo})
    {:ok, ppid} = GenServer.start_link(ProcessEngine, {simple_model, simple_data})
    assert ppid != nil
    assert GenServer.call(ppid, :get_data) == %{foo: :foo, bar: :bar}
    assert GenServer.call(ppid, :get_open_tasks) == []
  end
end
