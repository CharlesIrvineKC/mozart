defmodule Mozart.ProcessEngineTest do
  use ExUnit.Case

  alias Mozart.UserTaskManager
  alias Mozart.Util
  alias Mozart.ProcessEngine
  alias Mozart.ProcessManager

  @moduletag timeout: :infinity

  setup do

    ProcessManager.start_link(nil)
    UserTaskManager.start_link([])
    Enum.each(Util.get_testing_process_models(), fn model -> ProcessManager.load_process_model(model) end)
    %{ok: nil}
  end

  test "start server and get id" do
    model = ProcessManager.get_process_model(:simple_process_model)
    data = %{foo: "foo"}
    {:ok, ppid} = ProcessEngine.start_link(model, data)

    id = ProcessEngine.get_id(ppid)
    assert id != nil
    assert ProcessEngine.get_data(ppid) == %{foo: "foo", bar: :bar}
    assert ProcessEngine.is_complete(ppid) == true
  end

  test "execute process with choice returning :foo" do
    model = ProcessManager.get_process_model(:choice_process_model)
    data = %{value: 1}
    {:ok, ppid} = ProcessEngine.start_link(model, data)

    assert ProcessEngine.get_open_tasks(ppid) == []
    assert ProcessEngine.get_data(ppid) == %{value: 1, foo: :foo}
    assert ProcessEngine.is_complete(ppid) == true
  end

  test "execute process with choice returning :bar" do
    model = ProcessManager.get_process_model(:choice_process_model)
    data = %{value: 11}
    {:ok, ppid} = ProcessEngine.start_link(model, data)

    assert ProcessEngine.get_open_tasks(ppid) == []
    assert ProcessEngine.get_data(ppid) == %{value: 11, bar: :bar}
    assert ProcessEngine.is_complete(ppid) == true
  end

  test "one user task" do
    model = ProcessManager.get_process_model(:user_task_process_model)
    data = %{value: 0}
    {:ok, ppid} = ProcessEngine.start_link(model, data)

    assert ProcessEngine.get_data(ppid) == %{value: 0}
    assert ProcessEngine.get_open_tasks(ppid) == [:foo]
    assert ProcessEngine.is_complete(ppid) == false
    assert UserTaskManager.get_user_tasks() != []
  end

  test "complete one user task" do
    model = ProcessManager.get_process_model(:user_task_process_model)
    data = %{value: 0}
    {:ok, ppid} = ProcessEngine.start_link(model, data)

    assert ProcessEngine.get_data(ppid) == %{value: 0}
    assert ProcessEngine.get_open_tasks(ppid) == [:foo]

    ProcessEngine.complete_user_task(ppid, :foo, %{foo: :foo, bar: :bar})
    assert ProcessEngine.get_data(ppid) == %{value: 0, foo: :foo, bar: :bar}
    assert ProcessEngine.get_open_tasks(ppid) == []
  end

  test "complete one user task then sevice task" do
    model = ProcessManager.get_process_model(:user_task_then_service)
    data = %{value: 0}
    {:ok, ppid} = ProcessEngine.start_link(model, data)
    assert ProcessEngine.get_data(ppid) == %{value: 0}
    assert ProcessEngine.get_open_tasks(ppid) == [:user_task_1]
    ProcessEngine.complete_user_task(ppid, :user_task_1, %{foo: :foo, bar: :bar})
    assert ProcessEngine.get_data(ppid) == %{value: 0, foo: :foo, bar: :bar}
    assert ProcessEngine.get_open_tasks(ppid) == []
  end

  test "complete one servuce task then user task" do
    model = ProcessManager.get_process_model(:service_then_user_task)
    data = %{value: 0}
    {:ok, ppid} = ProcessEngine.start_link(model, data)
    assert ProcessEngine.get_data(ppid) == %{value: 1}
    assert ProcessEngine.get_open_tasks(ppid) == [:user_task_1]
    ProcessEngine.complete_user_task(ppid, :user_task_1, %{foo: :foo, bar: :bar})
    assert ProcessEngine.get_data(ppid) == %{value: 1, foo: :foo, bar: :bar}
    assert ProcessEngine.get_open_tasks(ppid) == []
  end

  test "set and get process state model" do
    model = ProcessManager.get_process_model(:simple_process_model)
    data = %{foo: :foo}
    {:ok, ppid} = GenServer.start_link(ProcessEngine, {model, data})
    assert GenServer.call(ppid, :get_model) == model
  end

  test "set and get data" do
    data = %{value: 1}
    model = ProcessManager.get_process_model(:simple_process_model)
    {:ok, ppid} = ProcessEngine.start_link(model, data)
    ProcessEngine.set_data(ppid, data)
    assert ProcessEngine.get_data(ppid) == data
  end

  test "get process model open tasks" do
    model = ProcessManager.get_process_model(:simple_process_model)
    data = %{value: 1}
    {:ok, ppid} = ProcessEngine.start_link(model, data)
    assert ProcessEngine.get_open_tasks(ppid) == []
    assert ProcessEngine.is_complete(ppid) == true
  end

  test "complete increment by one task" do
    model = ProcessManager.get_process_model(:increment_by_one_process)
    data = %{value: 0}
    {:ok, ppid} = ProcessEngine.start_link(model, data)
    assert ProcessEngine.get_data(ppid) == %{value: 1}
    assert ProcessEngine.get_open_tasks(ppid) == []
    assert ProcessEngine.is_complete(ppid) == true
  end

  test "two increment tasks in a row" do
    model = ProcessManager.get_process_model(:increment_by_one_twice_process)
    data = %{value: 0}
    {:ok, ppid} = ProcessEngine.start_link(model, data)
    assert ProcessEngine.get_data(ppid) == %{value: 3}
    assert ProcessEngine.get_open_tasks(ppid) == []
    assert ProcessEngine.is_complete(ppid) == true
  end

  test "Three increment tasks in a row" do
    model = ProcessManager.get_process_model(:three_increment_by_one_process)
    data = %{value: 0}
    {:ok, ppid} = ProcessEngine.start_link(model, data)
    assert ProcessEngine.get_data(ppid) == %{value: 6}
    assert ProcessEngine.get_open_tasks(ppid) == []
    assert ProcessEngine.is_complete(ppid) == true
  end
end
