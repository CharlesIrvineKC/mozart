defmodule Mozart.ProcessEngineTest do
  use ExUnit.Case

  alias Mozart.Util
  alias Mozart.ProcessEngine

  test "start server and get id" do
    model = Util.get_simple_model()
    data = %{foo: "foo"}
    {:ok, server} = GenServer.start_link(ProcessEngine, {model, data})
    id = GenServer.call(server, :get_id)
    assert id != nil
    assert GenServer.call(server, :get_data) == %{foo: "foo"}
  end

  test "set and get process state model" do
    model = Util.get_simple_model()
    data = "foo"
    {:ok, server} = GenServer.start_link(ProcessEngine, {model, data})
    assert GenServer.call(server, :get_model) == model
  end

  test "set and get data" do
    data = %{value: 1}
    model = Util.get_simple_model()
    {:ok, server} = GenServer.start_link(ProcessEngine, {model, data})
    GenServer.cast(server, {:set_data, data})
    assert GenServer.call(server, :get_data) == data
  end

  test "get process model open tasks" do
    model = Util.get_simple_model()
    data = %{value: 1}
    {:ok, server} = GenServer.start_link(ProcessEngine, {model, data})
    assert GenServer.call(server, :get_open_tasks) == [:foo]
  end

  test "complete increment by one task" do
    model = Util.get_increment_by_one_model()
    data = %{value: 0}
    {:ok, server} = GenServer.start_link(ProcessEngine, {model, data})
    assert GenServer.call(server, :get_data) == %{value: 1}
  end
end
