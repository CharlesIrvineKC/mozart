defmodule Mozart.ProcessEngineTest do
  use ExUnit.Case

  alias Mozart.TestModels
  alias Mozart.ProcessEngine, as: PE
  alias Mozart.ProcessModelService, as: PMS
  alias Mozart.ProcessService, as: PS
  alias Phoenix.PubSub

  test "process with a single service task" do
    PMS.clear_then_load_process_models(TestModels.single_service_task())
    data = %{value: 0}

    {:ok, ppid, _uid} = PE.start_supervised_pe(:process_with_single_service_task, data)
    PE.execute(ppid)
    Process.sleep(50)
  end

  test "call process with a subscribe task" do
    PMS.clear_then_load_process_models(TestModels.call_process_subscribe_task())
    data = %{value: 0}

    {:ok, ppid, uid} = PE.start_supervised_pe(:process_with_subscribe_task, data)
    PE.execute(ppid)
    Process.sleep(50)
    PubSub.broadcast(:pubsub, "pe_topic", {:message, {2, 2}})
    Process.sleep(100)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{value: 4}
    assert completed_process.complete == true
  end

  test "call process with an receive event task" do
    PMS.clear_then_load_process_models(TestModels.call_process_receive_event_task())
    data = %{}

    {:ok, ppid, uid} = PE.start_supervised_pe(:process_with_receive_event_task, data)
    PE.execute(ppid)
    [task_instance] = Map.values(PE.get_task_instances(ppid))
    send(ppid, {:event_received, task_instance.uid, %{income: 1000000}})
    Process.sleep(50)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{income: 1000000}
    assert completed_process.complete == true
  end

  test "call process with one timer task" do
    PMS.clear_then_load_process_models(TestModels.call_timer_tasks())
    data = %{}

    {:ok, ppid, uid} = PE.start_supervised_pe(:call_timer_task, data)
    PE.execute(ppid)
    Process.sleep(5000)
    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{}
    assert completed_process.complete == true
  end

  test "call an external service" do
    PMS.clear_then_load_process_models(TestModels.call_exteral_services())
    data = %{}

    {:ok, ppid, uid} = PE.start_supervised_pe(:call_external_services, data)
    PE.execute(ppid)
    Process.sleep(2000)
    assert PS.get_completed_process(uid) != nil
  end

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
    task_instances = Map.values(PE.get_task_instances(ppid))
    assert Enum.map(task_instances, fn t_i -> t_i.name end) == [:user_task]
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
    assert Enum.map(Map.values(task_instances), fn t_i -> t_i.name end) == [:user_task]

    [task_instance] = Map.values(task_instances)
    PE.complete_user_task(ppid, task_instance.uid, %{value: 0, foo: :foo, bar: :bar})
    Process.sleep(10)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{value: 0, foo: :foo, bar: :bar}
    assert completed_process.complete == true
  end

  test "recover lost state and proceed" do
    PMS.clear_then_load_process_models(TestModels.get_testing_process_models())
    data = %{value: "foobar"}
    {:ok, ppid, uid} = PE.start_supervised_pe(:two_user_tasks_then_service, data)
    PE.execute(ppid)
    Process.sleep(100)

    [task_instance] = Map.values(PE.get_task_instances(ppid))
    PE.complete_user_task(ppid, task_instance.uid, %{user_task_1: true})
    Process.sleep(50)
    assert PE.get_data(ppid) ==  %{value: "foobar", user_task_1: true}

    [task_instance] = Map.values(PE.get_task_instances(ppid))
    PE.complete_user_task(ppid, task_instance.uid, %{user_task_2: true})
    Process.sleep(100)

    new_pid = PS.get_process_ppid(uid)
    assert PE.get_data(new_pid) ==  %{value: "foobar", user_task_1: true}

    [task_instance] = Map.values(PE.get_task_instances(new_pid))
    PE.set_data(new_pid, %{value: 1, bar: :bar, foo: :foo})
    PE.complete_user_task(new_pid, task_instance.uid, %{foobar: :foobar})
    Process.sleep(100)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{value: 2, foo: :foo, bar: :bar, foobar: :foobar}
    assert completed_process.complete == true
  end

  test "complete one user task then sevice task" do
    PMS.clear_then_load_process_models(TestModels.get_testing_process_models())
    data = %{value: 0}
    {:ok, ppid, uid} = PE.start_supervised_pe(:user_task_then_service, data)
    PE.execute(ppid)
    Process.sleep(10)
    assert PE.get_data(ppid) == %{value: 0}
    task_names = Enum.map(Map.values(PE.get_task_instances(ppid)), fn t -> t.name end)
    assert task_names == [:user_task_1]
    [task_instance] = Map.values(PE.get_task_instances(ppid))

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

    task_uids = Map.keys(PE.get_task_instances(ppid))
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

  test "test correcting bad data and re-executing" do
    # Will cause a process restart due to adding 1 to "foobar"
    PMS.clear_then_load_process_models(TestModels.get_testing_process_models())
    data = %{value: "foobar"}
    {:ok, ppid, uid} = PE.start_supervised_pe(:increment_by_one_process, data)
    PE.execute(ppid)
    Process.sleep(100)

    # Process will have been restarted. Get new pid.
    new_pid = PS.get_process_ppid(uid)
    # Correct data
    PE.set_data(new_pid, %{value: 1})
    PE.execute(new_pid)
    Process.sleep(50)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.complete == true
    assert completed_process.data == %{value: 2}
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
    assert completed_process.task_instances == %{}
  end
end
