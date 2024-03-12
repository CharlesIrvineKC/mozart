defmodule Mozart.ProcessEngineTest do
  use ExUnit.Case

  alias Mozart.Data.ProcessState
  alias Mozart.Util
  alias Mozart.ProcessEngine

  setup do
    {:ok, server} = GenServer.start_link(ProcessEngine, %ProcessState{})
    %{server: server}
  end

  test "start server and get id", %{server: server} do
    assert server != nil
    id = GenServer.call(server, :get_id)
    assert id != nil
  end

  test "set and get process state model", %{server: server} do
    model = Util.get_simple_model()
    GenServer.cast(server, {:set_model, model})
    assert GenServer.call(server, :get_model) == model
  end

  test "set and get data", %{server: server} do
    data = %{value: 1}
    GenServer.cast(server, {:set_data, data})
    assert GenServer.call(server, :get_data) == data
  end

  test "get process model tasks", %{server: server} do
    model = GenServer.call(server, :get_model)
    assert model.name == "foo"
    assert model.tasks == [:foo]
    assert model.initial_task == :foo
  end

  test "complete increment by one task", %{server: _server, state: state} do
    IO.inspect(state)
  end
end
