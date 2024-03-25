defmodule Mozart.ProcessEngineTest do
  use ExUnit.Case

  alias Mozart.Util
  alias Mozart.ProcessEngine

  @moduletag timeout: :infinity

  test "start server and get id" do
    model = Util.get_simple_model()
    data = %{foo: "foo"}
    {:ok, server} = GenServer.start_link(ProcessEngine, {model, data})
    id = GenServer.call(server, :get_id)
    assert id != nil
    assert GenServer.call(server, :get_data) == %{foo: "foo", bar: :bar}
  end

  test "one user task" do
    model = Util.get_simple_user_task_model()
    data = %{value: 0}
    {:ok, server} = GenServer.start_link(ProcessEngine, {model, data})
    assert GenServer.call(server, :get_data) == %{value: 0}
    assert GenServer.call(server, :get_open_tasks) == [:foo]
  end

  test "complete one user task" do
    model = Util.get_simple_user_task_model()
    data = %{value: 0}
    {:ok, server} = GenServer.start_link(ProcessEngine, {model, data})
    assert GenServer.call(server, :get_data) == %{value: 0}
    assert GenServer.call(server, :get_open_tasks) == [:foo]
    GenServer.call(server, {:complete_user_task, :foo, %{foo: :foo, bar: :bar}})
    assert GenServer.call(server, :get_data) == %{value: 0, foo: :foo, bar: :bar}
    assert GenServer.call(server, :get_open_tasks) == []
  end

  test "complete one user task then sevice task" do
    model = Util.get_simple_user_task_then_service_task_model()
    data = %{value: 0}
    {:ok, server} = GenServer.start_link(ProcessEngine, {model, data})
    assert GenServer.call(server, :get_data) == %{value: 0}
    assert GenServer.call(server, :get_open_tasks) == [:user_task_1]
    GenServer.call(server, {:complete_user_task, :user_task_1, %{foo: :foo, bar: :bar}}, :infinity)
    assert GenServer.call(server, :get_data) == %{value: 0, foo: :foo, bar: :bar}
    assert GenServer.call(server, :get_open_tasks) == []
  end

  test "complete one servuce task then user task" do
    model = Util.get_service_task_then_simple_user_task_model()
    data = %{value: 0}
    {:ok, server} = GenServer.start_link(ProcessEngine, {model, data})
    assert GenServer.call(server, :get_data) == %{value: 1}
    assert GenServer.call(server, :get_open_tasks) == [:user_task_1]
    GenServer.call(server, {:complete_user_task, :user_task_1, %{foo: :foo, bar: :bar}}, :infinity)
    assert GenServer.call(server, :get_data) == %{value: 1, foo: :foo, bar: :bar}
    assert GenServer.call(server, :get_open_tasks) == []
  end

  test "set and get process state model" do
    model = Util.get_simple_model()
    data = %{foo: :foo}
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
    assert GenServer.call(server, :get_open_tasks) == []
  end

  test "complete increment by one task" do
    model = Util.get_increment_by_one_model()
    data = %{value: 0}
    {:ok, server} = GenServer.start_link(ProcessEngine, {model, data})
    assert GenServer.call(server, :get_data) == %{value: 1}
    assert GenServer.call(server, :get_open_tasks) == []
  end

  test "two increment tasks in a row" do
    model = Util.get_increment_twice_by_one_model()
    data = %{value: 0}
    {:ok, server} = GenServer.start_link(ProcessEngine, {model, data})
    assert GenServer.call(server, :get_data) == %{value: 3}
    assert GenServer.call(server, :get_open_tasks) == []
  end

  test "Three increment tasks in a row" do
    model = Util.get_increment_three_times_by_one_model()
    data = %{value: 0}
    {:ok, server} = GenServer.start_link(ProcessEngine, {model, data})
    assert GenServer.call(server, :get_data) == %{value: 6}
    assert GenServer.call(server, :get_open_tasks) == []
  end
end
