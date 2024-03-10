defmodule Mozart.ProcessEngineTest do
  use ExUnit.Case

  alias Mozart.Data.ProcessModel
  alias Mozart.Util
  alias Mozart.ProcessEngine

  setup do
    state = Util.get_simple_state()
    {:ok, server} = GenServer.start_link(ProcessEngine, state)
    %{server: server, state: state}
  end

  test "start server", %{server: server} do
    assert server != nil
  end

  test "get process state model", %{server: server} do
    model = GenServer.call(server, :get_model)
    %ProcessModel{name: name} = model
    assert name == "foo"
  end

  test "get process model tasks", %{server: server} do
    model = GenServer.call(server, :get_model)
    assert model.name == "foo"
    assert model.tasks == [:foo]
    assert model.initial_task == :foo
  end
end
