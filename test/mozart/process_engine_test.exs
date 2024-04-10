defmodule Mozart.ProcessEngineTest do
  use ExUnit.Case

  alias Mozart.Util
  alias Mozart.ProcessEngine

  @moduletag timeout: :infinity

  test "start server and get id" do
    model = Util.get_simple_model()
    data = %{foo: "foo"}
    {:ok, ppid} = ProcessEngine.start_link(model, data)

    id = ProcessEngine.get_id(ppid)
    assert id != nil
    assert ProcessEngine.get_data(ppid) == %{foo: "foo", bar: :bar}
    assert ProcessEngine.is_complete(ppid) == true
  end

  test "execute process with choice returning :foo" do
    model = Util.get_choice_model()
    data = %{value: 1}
    {:ok, ppid} = ProcessEngine.start_link(model, data)

    assert ProcessEngine.get_open_tasks(ppid) == []
    assert ProcessEngine.get_data(ppid) == %{value: 1, foo: :foo}
    assert ProcessEngine.is_complete(ppid) == true
  end

  test "execute process with choice returning :bar" do
    model = Util.get_choice_model()
    data = %{value: 11}
    {:ok, ppid} = ProcessEngine.start_link(model, data)

    assert ProcessEngine.get_open_tasks(ppid) == []
    assert ProcessEngine.get_data(ppid) == %{value: 11, bar: :bar}
    assert ProcessEngine.is_complete(ppid) == true
  end

  test "one user task" do
    model = Util.get_simple_user_task_model()
    data = %{value: 0}
    {:ok, ppid} = ProcessEngine.start_link(model, data)

    assert ProcessEngine.get_data(ppid) == %{value: 0}
    assert ProcessEngine.get_open_tasks(ppid) == [:foo]
    assert ProcessEngine.is_complete(ppid) == false
  end

  test "complete one user task" do
    model = Util.get_simple_user_task_model()
    data = %{value: 0}
    {:ok, ppid} = ProcessEngine.start_link(model, data)

    assert ProcessEngine.get_data(ppid) == %{value: 0}
    assert ProcessEngine.get_open_tasks(ppid) == [:foo]

    ProcessEngine.complete_user_task(ppid, :foo, %{foo: :foo, bar: :bar})
    assert ProcessEngine.get_data(ppid) == %{value: 0, foo: :foo, bar: :bar}
    assert ProcessEngine.get_open_tasks(ppid) == []
  end

  test "complete one user task then sevice task" do
    model = Util.get_simple_user_task_then_service_task_model()
    data = %{value: 0}
    {:ok, ppid} = ProcessEngine.start_link(model, data)
    assert ProcessEngine.get_data(ppid) == %{value: 0}
    assert ProcessEngine.get_open_tasks(ppid) == [:user_task_1]
    ProcessEngine.complete_user_task(ppid, :user_task_1, %{foo: :foo, bar: :bar})
    assert ProcessEngine.get_data(ppid) == %{value: 0, foo: :foo, bar: :bar}
    assert ProcessEngine.get_open_tasks(ppid) == []
  end

  test "complete one servuce task then user task" do
    model = Util.get_service_task_then_simple_user_task_model()
    data = %{value: 0}
    {:ok, ppid} = ProcessEngine.start_link(model, data)
    assert ProcessEngine.get_data(ppid) == %{value: 1}
    assert ProcessEngine.get_open_tasks(ppid) == [:user_task_1]
    ProcessEngine.complete_user_task(ppid, :user_task_1, %{foo: :foo, bar: :bar})
    assert ProcessEngine.get_data(ppid) == %{value: 1, foo: :foo, bar: :bar}
    assert ProcessEngine.get_open_tasks(ppid) == []
  end

  test "set and get process state model" do
    model = Util.get_simple_model()
    data = %{foo: :foo}
    {:ok, ppid} = GenServer.start_link(ProcessEngine, {model, data})
    assert GenServer.call(ppid, :get_model) == model
  end

  test "set and get data" do
    data = %{value: 1}
    model = Util.get_simple_model()
    {:ok, ppid} = ProcessEngine.start_link(model, data)
    ProcessEngine.set_data(ppid, data)
    assert ProcessEngine.get_data(ppid) == data
  end

  test "get process model open tasks" do
    model = Util.get_simple_model()
    data = %{value: 1}
    {:ok, ppid} = ProcessEngine.start_link(model, data)
    assert ProcessEngine.get_open_tasks(ppid) == []
    assert ProcessEngine.is_complete(ppid) == true
  end

  test "complete increment by one task" do
    model = Util.get_increment_by_one_model()
    data = %{value: 0}
    {:ok, ppid} = ProcessEngine.start_link(model, data)
    assert ProcessEngine.get_data(ppid) == %{value: 1}
    assert ProcessEngine.get_open_tasks(ppid) == []
    assert ProcessEngine.is_complete(ppid) == true
  end

  test "two increment tasks in a row" do
    model = Util.get_increment_twice_by_one_model()
    data = %{value: 0}
    {:ok, ppid} = ProcessEngine.start_link(model, data)
    assert ProcessEngine.get_data(ppid) == %{value: 3}
    assert ProcessEngine.get_open_tasks(ppid) == []
    assert ProcessEngine.is_complete(ppid) == true
  end

  test "Three increment tasks in a row" do
    model = Util.get_increment_three_times_by_one_model()
    data = %{value: 0}
    {:ok, ppid} = ProcessEngine.start_link(model, data)
    assert ProcessEngine.get_data(ppid) == %{value: 6}
    assert ProcessEngine.get_open_tasks(ppid) == []
    assert ProcessEngine.is_complete(ppid) == true
  end
end
