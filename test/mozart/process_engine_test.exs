defmodule Mozart.ProcessEngineTest do
  use ExUnit.Case

  alias Mozart.TestModels
  alias Mozart.ProcessEngine, as: PE
  alias Mozart.ProcessModelService, as: PMS
  alias Mozart.ProcessService, as: PS

  # test "call an external service" do
  #   PMS.clear_then_load_process_models(TestModels.call_exteral_services())
  #   model = PMS.get_process_model(:call_external_services)
  #   data = %{}

  #   {:ok, ppid, uid} = PE.start_supervised_pe(model, data)
  #   Process.sleep(10)
  #   PE.execute(ppid)
  #   assert PS.get_completed_process(uid) != nil
  # end

  test "complex process model" do
    PMS.clear_then_load_process_models(TestModels.get_complex_process_models())
    data = %{value: 1}

    {:ok, ppid, uid} = PE.start_supervised_pe(:call_process_model, data)
    PE.execute(ppid)
    Process.sleep(10)
    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{value: 7}
    assert completed_process.complete == true
  end

  test "start server and get id" do
    PMS.clear_then_load_process_models(TestModels.get_testing_process_models())
    data = %{foo: "foo"}

    {:ok, ppid, uid} = PE.start_supervised_pe(:simple_process_model, data)
    PE.execute(ppid)
    Process.sleep(10)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{foo: "foo", bar: :bar}
    assert completed_process.complete == true
  end

  test "execute process with subprocess" do
    PMS.clear_then_load_process_models(TestModels.get_testing_process_models())
    data = %{value: 1}
    {:ok, ppid, _uid} = PE.start_supervised_pe(:simple_call_process_model, data)
    PE.execute(ppid)
    Process.sleep(10)
  end

  test "execute process with service subprocess" do
    PMS.clear_then_load_process_models(TestModels.get_testing_process_models())
    data = %{value: 1}
    {:ok, ppid, uid} = PE.start_supervised_pe(:simple_call_service_process_model, data)
    PE.execute(ppid)
    Process.sleep(10)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{value: 1, service: :service}
    assert completed_process.complete == true
  end

  test "execute process with choice and join" do
    PMS.clear_then_load_process_models(TestModels.get_parallel_process_models())
    data = %{value: 1}
    {:ok, ppid, uid} = PE.start_supervised_pe(:parallel_process_model, data)
    PE.execute(ppid)
    Process.sleep(10)

    completed_process = PS.get_completed_process(uid)

    assert completed_process.data == %{
             value: 1,
             foo: :foo,
             bar: :bar,
             foo_bar: :foo_bar,
             final: :final
           }

    assert completed_process.complete == true
  end

  test "execute process with choice returning :foo" do
    PMS.clear_then_load_process_models(TestModels.get_testing_process_models())
    data = %{value: 1}
    {:ok, ppid, uid} = PE.start_supervised_pe(:choice_process_model, data)
    PE.execute(ppid)
    Process.sleep(20)
    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{value: 1, foo: :foo}
    assert completed_process.complete == true
  end

  test "execute process with choice returning :bar" do
    PMS.clear_then_load_process_models(TestModels.get_testing_process_models())
    data = %{value: 11}
    {:ok, ppid, uid} = PE.start_supervised_pe(:choice_process_model, data)
    PE.execute(ppid)
    Process.sleep(10)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{value: 11, bar: :bar}
    assert completed_process.complete == true
  end

  test "one user task" do
    PMS.clear_then_load_process_models(TestModels.get_testing_process_models())
    data = %{value: 0}
    {:ok, ppid, _uid} = PE.start_supervised_pe(:user_task_process_model, data)
    PE.execute(ppid)
    Process.sleep(10)

    assert PE.get_data(ppid) == %{value: 0}
    task_instances = PE.get_task_instances(ppid)
    assert Enum.map(task_instances, fn t_i -> t_i.name end) == [:foo]
    assert PE.is_complete(ppid) == false
  end

  test "complete one user task" do
    PMS.clear_then_load_process_models(TestModels.get_testing_process_models())
    data = %{value: 0}
    {:ok, ppid, uid} = PE.start_supervised_pe(:user_task_process_model, data)
    PE.execute(ppid)
    Process.sleep(10)

    assert PE.get_data(ppid) == %{value: 0}
    task_instances = PE.get_task_instances(ppid)
    assert Enum.map(task_instances, fn t_i -> t_i.name end) == [:foo]

    [task_instance] = task_instances
    PE.complete_user_task(ppid, task_instance.uid, %{value: 0, foo: :foo, bar: :bar})
    Process.sleep(10)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{value: 0, foo: :foo, bar: :bar}
    assert completed_process.complete == true
  end

  test "complete one user task then sevice task" do
    PMS.clear_then_load_process_models(TestModels.get_testing_process_models())
    data = %{value: 0}
    {:ok, ppid, uid} = PE.start_supervised_pe(:user_task_then_service, data)
    PE.execute(ppid)
    Process.sleep(10)
    assert PE.get_data(ppid) == %{value: 0}
    task_names = Enum.map(PE.get_task_instances(ppid), fn t -> t.name end)
    assert task_names == [:user_task_1]
    [task_instance] = PE.get_task_instances(ppid)

    PE.complete_user_task(ppid, task_instance.uid, %{foo: :foo, bar: :bar})
    Process.sleep(10)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{value: 1, foo: :foo, bar: :bar}
    assert completed_process.complete == true
  end

  test "complete one servuce task then user task" do
    PMS.clear_then_load_process_models(TestModels.get_testing_process_models())
    data = %{value: 0}
    {:ok, ppid, uid} = PE.start_supervised_pe(:service_then_user_task, data)
    PE.execute(ppid)
    Process.sleep(10)
    assert PE.get_data(ppid) == %{value: 1}
    task_uids = Enum.map(PE.get_task_instances(ppid), fn t -> t.uid end)
    [task_uid] = task_uids

    PE.complete_user_task(ppid, task_uid, %{foo: :foo, bar: :bar})
    Process.sleep(10)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{value: 1, foo: :foo, bar: :bar}
    assert completed_process.complete == true
  end

  test "set and get process state model" do
    PMS.clear_then_load_process_models(TestModels.get_testing_process_models())
    data = %{foo: :foo}
    {:ok, ppid, uid} = PE.start_supervised_pe(:simple_process_model, data)
    PE.execute(ppid)
    Process.sleep(10)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.complete == true
    assert completed_process.model_name == :simple_process_model
  end

  test "set and get data" do
    PMS.clear_then_load_process_models(TestModels.get_testing_process_models())
    data = %{value: 1}
    {:ok, ppid, uid} = PE.start_supervised_pe(:simple_process_model, data)
    PE.execute(ppid)
    Process.sleep(10)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.complete == true
    assert completed_process.data == %{value: 1, bar: :bar}
  end

  test "get process model open tasks" do
    PMS.clear_then_load_process_models(TestModels.get_testing_process_models())
    data = %{value: 1}
    {:ok, ppid, uid} = PE.start_supervised_pe(:simple_process_model, data)
    #Process.sleep(10)
    PE.execute(ppid)
    Process.sleep(10)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.complete == true
    assert completed_process.data == %{value: 1, bar: :bar}
  end

  test "complete increment by one task" do
    PMS.clear_then_load_process_models(TestModels.get_testing_process_models())
    data = %{value: 0}
    {:ok, ppid, uid} = PE.start_supervised_pe(:increment_by_one_process, data)
    PE.execute(ppid)
    Process.sleep(10)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.complete == true
    assert completed_process.data == %{value: 1}
  end

  test "two increment tasks in a row" do
    PMS.clear_then_load_process_models(TestModels.get_testing_process_models())
    data = %{value: 0}
    {:ok, ppid, uid} = PE.start_supervised_pe(:increment_by_one_twice_process, data)
    PE.execute(ppid)
    Process.sleep(10)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.complete == true
    assert completed_process.data == %{value: 3}
  end

  test "Three increment tasks in a row" do
    PMS.clear_then_load_process_models(TestModels.get_testing_process_models())
    data = %{value: 0}
    {:ok, ppid, uid} = PE.start_supervised_pe(:three_increment_by_one_process, data)
    PE.execute(ppid)
    Process.sleep(10)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.complete == true
    assert completed_process.data == %{value: 6}
    assert completed_process.task_instances == []
  end
end
