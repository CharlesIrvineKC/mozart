defmodule Mozart.ProcessEngineTest do
  use ExUnit.Case

  alias Mozart.Util
  alias Mozart.ProcessEngine, as: PE
  alias Mozart.ProcessModelService, as: PMS

  @moduletag timeout: :infinity

  def load_process_models(models) do
    Enum.each(models, fn model -> PMS.load_process_model(model) end)
  end

  test "call an external service" do
    load_process_models(Util.call_exteral_services())
    model = PMS.get_process_model(:call_external_services)
    data = %{}

    {:ok, ppid} = PE.start_link(model, data)
    assert PE.get_data(ppid) != %{}
  end

  test "complex process model" do
    load_process_models(Util.get_complex_process_models())
    model = PMS.get_process_model(:call_process_model)
    data = %{value: 1}

    {:ok, ppid} = PE.start_link(model, data)
    assert PE.get_data(ppid) == %{value: 7}
    assert PE.is_complete(ppid) == true
  end

  test "start server and get id" do
    load_process_models(Util.get_testing_process_models())
    model = PMS.get_process_model(:simple_process_model)
    data = %{foo: "foo"}
    {:ok, ppid} = PE.start_link(model, data)

    assert PE.get_data(ppid) == %{foo: "foo", bar: :bar}
    assert PE.is_complete(ppid) == true
  end

  test "execute process with subprocess" do
    load_process_models(Util.get_testing_process_models())
    model = PMS.get_process_model(:simple_call_process_model)
    data = %{value: 1}
    {:ok, _ppid} = PE.start_link(model, data)

  end

  test "execute process with service subprocess" do
    load_process_models(Util.get_testing_process_models())
    model = PMS.get_process_model(:simple_call_service_process_model)
    data = %{value: 1}
    {:ok, ppid} = PE.start_link(model, data)
    assert PE.get_data(ppid) == %{value: 1, service: :service}

  end

  test "execute process with choice and join" do
    load_process_models(Util.get_parallel_process_models())
    model = PMS.get_process_model(:parallel_process_model)
    data = %{value: 1}
    {:ok, ppid} = PE.start_link(model, data)

    assert PE.get_task_instances(ppid) == []
    assert PE.get_data(ppid) == %{value: 1, foo: :foo, bar: :bar, foo_bar: :foo_bar, final: :final}
    assert PE.is_complete(ppid) == true
  end

  test "execute process with choice returning :foo" do
    load_process_models(Util.get_testing_process_models())
    model = PMS.get_process_model(:choice_process_model)
    data = %{value: 1}
    {:ok, ppid} = PE.start_link(model, data)

    assert PE.get_task_instances(ppid) == []
    assert PE.get_data(ppid) == %{value: 1, foo: :foo}
    assert PE.is_complete(ppid) == true
  end

  test "execute process with choice returning :bar" do
    load_process_models(Util.get_testing_process_models())
    model = PMS.get_process_model(:choice_process_model)
    data = %{value: 11}
    {:ok, ppid} = PE.start_link(model, data)

    assert PE.get_task_instances(ppid) == []
    assert PE.get_data(ppid) == %{value: 11, bar: :bar}
    assert PE.is_complete(ppid) == true
  end

  test "one user task" do
    load_process_models(Util.get_testing_process_models())
    model = PMS.get_process_model(:user_task_process_model)
    data = %{value: 0}
    {:ok, ppid} = PE.start_link(model, data)

    assert PE.get_data(ppid) == %{value: 0}
    task_instances = PE.get_task_instances(ppid)
    assert Enum.map(task_instances, fn t_i -> t_i.name end) == [:foo]
    assert PE.is_complete(ppid) == false
  end

  test "complete one user task" do
    load_process_models(Util.get_testing_process_models())
    model = PMS.get_process_model(:user_task_process_model)
    data = %{value: 0}
    {:ok, ppid} = PE.start_link(model, data)

    assert PE.get_data(ppid) == %{value: 0}
    task_instances = PE.get_task_instances(ppid)
    assert Enum.map(task_instances, fn t_i -> t_i.name end) == [:foo]

    [task_instance] = task_instances
    PE.complete_user_task(ppid, task_instance.uid, %{foo: :foo, bar: :bar})
    assert PE.get_data(ppid) == %{value: 0, foo: :foo, bar: :bar}
    assert PE.get_task_instances(ppid) == []
  end

  test "complete one user task then sevice task" do
    load_process_models(Util.get_testing_process_models())
    model = PMS.get_process_model(:user_task_then_service)
    data = %{value: 0}
    {:ok, ppid} = PE.start_link(model, data)
    assert PE.get_data(ppid) == %{value: 0}
    task_names = Enum.map(PE.get_task_instances(ppid), fn t -> t.name end)
    assert task_names == [:user_task_1]
    [task_instance] = PE.get_task_instances(ppid)
    PE.complete_user_task(ppid, task_instance.uid, %{foo: :foo, bar: :bar})
    assert PE.get_data(ppid) == %{value: 1, foo: :foo, bar: :bar}
    assert PE.is_complete(ppid) == true
    assert PE.get_task_instances(ppid) == []
  end

  test "complete one servuce task then user task" do
    load_process_models(Util.get_testing_process_models())
    model = PMS.get_process_model(:service_then_user_task)
    data = %{value: 0}
    {:ok, ppid} = PE.start_link(model, data)
    assert PE.get_data(ppid) == %{value: 1}
    task_uids = Enum.map(PE.get_task_instances(ppid), fn t -> t.uid end)
    [task_uid] = task_uids
    PE.complete_user_task(ppid, task_uid, %{foo: :foo, bar: :bar})
    assert PE.get_data(ppid) == %{value: 1, foo: :foo, bar: :bar}
    assert PE.get_task_instances(ppid) == []
  end

  test "set and get process state model" do
    load_process_models(Util.get_testing_process_models())
    model = PMS.get_process_model(:simple_process_model)
    data = %{foo: :foo}
    {:ok, ppid} = PE.start_link(model, data)
    assert PE.get_model(ppid) == model
  end

  test "set and get data" do
    load_process_models(Util.get_testing_process_models())
    data = %{value: 1}
    model = PMS.get_process_model(:simple_process_model)
    {:ok, ppid} = PE.start_link(model, data)
    PE.set_data(ppid, data)
    assert PE.get_data(ppid) == data
  end

  test "get process model open tasks" do
    load_process_models(Util.get_testing_process_models())
    model = PMS.get_process_model(:simple_process_model)
    data = %{value: 1}
    {:ok, ppid} = PE.start_link(model, data)
    assert PE.get_task_instances(ppid) == []
    assert PE.is_complete(ppid) == true
  end

  test "complete increment by one task" do
    load_process_models(Util.get_testing_process_models())
    model = PMS.get_process_model(:increment_by_one_process)
    data = %{value: 0}
    {:ok, ppid} = PE.start_link(model, data)
    assert PE.get_data(ppid) == %{value: 1}
    assert PE.get_task_instances(ppid) == []
    assert PE.is_complete(ppid) == true
  end

  test "two increment tasks in a row" do
    load_process_models(Util.get_testing_process_models())
    model = PMS.get_process_model(:increment_by_one_twice_process)
    data = %{value: 0}
    {:ok, ppid} = PE.start_link(model, data)
    assert PE.get_data(ppid) == %{value: 3}
    assert PE.get_task_instances(ppid) == []
    assert PE.is_complete(ppid) == true
  end

  test "Three increment tasks in a row" do
    load_process_models(Util.get_testing_process_models())
    model = PMS.get_process_model(:three_increment_by_one_process)
    data = %{value: 0}
    {:ok, ppid} = PE.start_link(model, data)
    assert PE.get_data(ppid) == %{value: 6}
    assert PE.get_task_instances(ppid) == []
    assert PE.is_complete(ppid) == true
  end
end
