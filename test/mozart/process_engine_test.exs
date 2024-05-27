defmodule Mozart.ProcessEngineTest do
  use ExUnit.Case

  alias Mozart.Models.TestModels
  alias Mozart.ProcessEngine, as: PE
  alias Mozart.ProcessModelService, as: PMS
  alias Mozart.ProcessService, as: PS

  test "call json service" do
    PMS.clear_then_load_process_models(TestModels.call_exteral_services())
    data = %{}

    {:ok, ppid, uid} = PE.start_process(:call_external_service, data)
    catch_exit(PE.execute_and_wait(ppid))

    completed_process = PS.get_completed_process(uid)

    assert completed_process.data == %{
             todo_data: %{
               "completed" => false,
               "id" => 1,
               "title" => "delectus aut autem",
               "userId" => 1
             }
           }

    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 1
  end

  test "test for loan approval" do
    PMS.clear_then_load_process_models(TestModels.get_loan_models())
    data = %{loan_args: [income: 3000]}

    {:ok, ppid, uid} = PE.start_process(:load_approval, data)
    catch_exit(PE.execute_and_wait(ppid))

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{loan_args: [income: 3000], status: "declined"}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 1
  end

  test "process with single send event task" do
    PMS.clear_then_load_process_models(TestModels.single_send_event_task())
    data = %{value: 0}

    {:ok, ppid, uid} = PE.start_process(:process_with_single_send_evet_task, data)
    catch_exit(PE.execute_and_wait(ppid))

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{value: 0}
    assert completed_process.complete == true
  end

  test "process with receive event and another with a send event" do
    PMS.clear_then_load_process_models(TestModels.send_task_to_receive_task())
    data = %{}

    {:ok, r_ppid, r_uid} = PE.start_process(:process_with_receive_task, data)
    PE.execute_and_wait(r_ppid)

    {:ok, s_ppid, s_uid} = PE.start_process(:process_with_single_send_task, data)
    catch_exit(PE.execute_and_wait(s_ppid))

    ps_state = PS.get_state()
    completed_processes = ps_state.completed_processes
    assert completed_processes[r_uid].complete == true
    assert completed_processes[s_uid].complete == true
    assert length(completed_processes[r_uid].completed_tasks) == 1
    assert length(completed_processes[s_uid].completed_tasks) == 1
  end

  test "process with a single service task" do
    PMS.clear_then_load_process_models(TestModels.single_service_task())
    data = %{value: 0}

    {:ok, ppid, _uid} = PE.start_process(:process_with_single_service_task, data)
    PE.execute(ppid)
  end

  # test "call process with a receive event task" do
  #   PMS.clear_then_load_process_models(TestModels.call_process_receive_event_task())
  #   data = %{value: 0}

  #   {:ok, ppid, uid} = PE.start_process(:process_with_receive_event_task, data)
  #   PE.execute_and_wait(ppid)

  #   PubSub.broadcast(:pubsub, "pe_topic", {:message, {2, 2}})
  #   Process.sleep(100)

  #   completed_process = PS.get_completed_process(uid)
  #   assert completed_process.data == %{value: 4}
  #   assert completed_process.complete == true
  # end

  test "call process with one timer task" do
    PMS.clear_then_load_process_models(TestModels.call_timer_tasks())
    data = %{}

    {:ok, ppid, uid} = PE.start_process(:call_timer_task, data)
    PE.execute_and_wait(ppid)

    Process.monitor(ppid)
    assert_receive(_msg, 500)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 2
  end

  # test "call an external service" do
  #   PMS.clear_then_load_process_models(TestModels.call_exteral_services())
  #   data = %{}

  #   {:ok, ppid, uid} = PE.start_process(:call_external_services, data)
  #   PE.execute(ppid)
  #   Process.sleep(2000)
  #   assert PS.get_completed_process(uid) != nil
  # end

  test "complex process model" do
    PMS.clear_then_load_process_models(TestModels.get_complex_process_models())
    data = %{value: 1}

    {:ok, ppid, uid} = PE.start_process(:call_process_model, data)

    PE.execute_and_wait(ppid)

    Process.monitor(ppid)
    assert_receive(_msg, 500)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{value: 7}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 7
  end

  test "start server and get id" do
    PMS.clear_then_load_process_models(TestModels.get_testing_process_models())
    data = %{foo: "foo"}

    {:ok, ppid, uid} = PE.start_process(:simple_process_model, data)
    catch_exit(PE.execute_and_wait(ppid))

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{foo: "foo", bar: :bar}
    assert completed_process.complete == true
  end

  test "execute process with subprocess with a user subprocess" do
    PMS.clear_then_load_process_models(TestModels.get_testing_process_models())
    data = %{value: 1}
    {:ok, ppid, _uid} = PE.start_process(:simple_call_process_model, data)
    PE.execute(ppid)
  end

  test "execute process with service subprocess" do
    PMS.clear_then_load_process_models(TestModels.get_testing_process_models())
    data = %{value: 1}
    {:ok, ppid, uid} = PE.start_process(:simple_call_service_process_model, data)
    PE.execute_and_wait(ppid)

    Process.monitor(ppid)
    assert_receive(_msg, 500)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{value: 1, service: :service}
    assert completed_process.complete == true
  end

  test "execute process with parallel task and join" do
    PMS.clear_then_load_process_models(TestModels.get_parallel_process_models())
    data = %{value: 1}
    {:ok, ppid, uid} = PE.start_process(:parallel_process_model, data)
    catch_exit(PE.execute_and_wait(ppid))

    completed_process = PS.get_completed_process(uid)

    assert completed_process.data == %{
             value: 1,
             foo: :foo,
             bar: :bar,
             foo_bar: :foo_bar,
             final: :final
           }

    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 6
  end

  test "execute process with choice returning :foo" do
    PMS.clear_then_load_process_models(TestModels.get_testing_process_models())
    data = %{value: 1}
    {:ok, ppid, uid} = PE.start_process(:choice_process_model, data)
    catch_exit(PE.execute_and_wait(ppid))

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{value: 1, foo: :foo}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 2
  end

  test "execute process with choice returning :bar" do
    PMS.clear_then_load_process_models(TestModels.get_testing_process_models())
    data = %{value: 11}
    {:ok, ppid, uid} = PE.start_process(:choice_process_model, data)
    catch_exit(PE.execute_and_wait(ppid))

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{value: 11, bar: :bar}
    assert completed_process.complete == true
  end

  test "one user task" do
    PMS.clear_then_load_process_models(TestModels.get_testing_process_models())
    data = %{value: 0}
    {:ok, ppid, _uid} = PE.start_process(:user_task_process_model, data)
    PE.execute_and_wait(ppid)

    assert PE.get_data(ppid) == %{value: 0}
    open_tasks = Map.values(PE.get_open_tasks(ppid))
    assert Enum.map(open_tasks, fn t_i -> t_i.name end) == [:user_task]
    assert PE.is_complete(ppid) == false
  end

  test "complete one user task" do
    PMS.clear_then_load_process_models(TestModels.get_testing_process_models())
    data = %{value: 0}
    {:ok, ppid, uid} = PE.start_process(:user_task_process_model, data)
    PE.execute_and_wait(ppid)

    assert PE.get_data(ppid) == %{value: 0}
    open_tasks = PE.get_open_tasks(ppid)
    assert Enum.map(Map.values(open_tasks), fn t_i -> t_i.name end) == [:user_task]

    [task_instance] = Map.values(open_tasks)
    catch_exit(PE.complete_user_task(ppid, task_instance.uid, %{value: 0, foo: :foo, bar: :bar}))
    Process.sleep(10)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{value: 0, foo: :foo, bar: :bar}
    assert completed_process.complete == true
  end

  test "recover lost state and proceed" do
    # Start process with two user tasks and then a service task
    PMS.clear_then_load_process_models(TestModels.get_testing_process_models())
    data = %{value: "foobar"}
    {:ok, ppid, uid} = PE.start_process(:two_user_tasks_then_service, data)
    PE.execute_and_wait(ppid)

    # Get the first user task and complete it.
    [task_instance] = Map.values(PE.get_open_tasks(ppid))
    PE.complete_user_task(ppid, task_instance.uid, %{user_task_1: true})
    assert PE.get_data(ppid) == %{value: "foobar", user_task_1: true}

    # Get the second user task and complete it. This will cause the service
    # task to fail due to adding 1 to "foobar". The process will terminate and
    # the supervisor will restart it recovering state including the data inserted
    # by the first user task.
    [task_instance] = Map.values(PE.get_open_tasks(ppid))
    catch_exit(PE.complete_user_task(ppid, task_instance.uid, %{user_task_2: true}))
    Process.sleep(100)

    # Get the restarted process pid from PS and make sure the state is as expected.
    new_pid = PS.get_process_ppid(uid)
    assert PE.get_data(new_pid) == %{value: "foobar", user_task_1: true}

    # Get the recoved second user task. Reset value to a numerical value, i.e. 1.
    # Then complete the user task. This time the service task will complete
    # without the exception.
    [task_instance] = Map.values(PE.get_open_tasks(new_pid))
    data = PE.get_data(new_pid)
    PE.set_data(new_pid, Map.merge(data, %{value: 1}))
    catch_exit(PE.complete_user_task(new_pid, task_instance.uid, %{user_task_2: true}))

    Process.monitor(new_pid)
    assert_receive({:DOWN, _ref, :process, _object, _reason})

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{value: 2, user_task_1: true, user_task_2: true}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 3
  end

  test "complete one user task then sevice task" do
    PMS.clear_then_load_process_models(TestModels.get_testing_process_models())
    data = %{value: 0}
    {:ok, ppid, uid} = PE.start_process(:user_task_then_service, data)
    PE.execute_and_wait(ppid)

    # Process.sleep(10)
    assert PE.get_data(ppid) == %{value: 0}
    task_names = Enum.map(Map.values(PE.get_open_tasks(ppid)), fn t -> t.name end)
    assert task_names == [:user_task_1]
    [task_instance] = Map.values(PE.get_open_tasks(ppid))

    catch_exit(PE.complete_user_task(ppid, task_instance.uid, %{foo: :foo, bar: :bar}))

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{value: 1, foo: :foo, bar: :bar}
    assert completed_process.complete == true
  end

  test "complete one servuce task then user task" do
    PMS.clear_then_load_process_models(TestModels.get_testing_process_models())
    data = %{value: 0}
    {:ok, ppid, uid} = PE.start_process(:service_then_user_task, data)
    PE.execute_and_wait(ppid)
    assert PE.get_data(ppid) == %{value: 1}

    task_uids = Map.keys(PE.get_open_tasks(ppid))
    [task_uid] = task_uids
    catch_exit(PE.complete_user_task(ppid, task_uid, %{foo: :foo, bar: :bar}))

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{value: 1, foo: :foo, bar: :bar}
    assert completed_process.complete == true
  end

  test "set and get process state model" do
    PMS.clear_then_load_process_models(TestModels.get_testing_process_models())
    data = %{foo: :foo}
    {:ok, ppid, uid} = PE.start_process(:simple_process_model, data)
    catch_exit(PE.execute_and_wait(ppid))

    completed_process = PS.get_completed_process(uid)
    assert completed_process.complete == true
    assert completed_process.model_name == :simple_process_model
  end

  test "set and get data" do
    PMS.clear_then_load_process_models(TestModels.get_testing_process_models())
    data = %{value: 1}
    {:ok, ppid, uid} = PE.start_process(:simple_process_model, data)
    catch_exit(PE.execute_and_wait(ppid))

    completed_process = PS.get_completed_process(uid)
    assert completed_process.complete == true
    assert completed_process.data == %{value: 1, bar: :bar}
  end

  test "get process model open tasks" do
    PMS.clear_then_load_process_models(TestModels.get_testing_process_models())
    data = %{value: 1}
    {:ok, ppid, uid} = PE.start_process(:simple_process_model, data)
    catch_exit(PE.execute_and_wait(ppid))

    completed_process = PS.get_completed_process(uid)
    assert completed_process.complete == true
    assert completed_process.data == %{value: 1, bar: :bar}
  end

  test "complete increment by one task" do
    PMS.clear_then_load_process_models(TestModels.get_testing_process_models())
    data = %{value: 0}
    {:ok, ppid, uid} = PE.start_process(:increment_by_one_process, data)
    catch_exit(PE.execute_and_wait(ppid))

    completed_process = PS.get_completed_process(uid)
    assert completed_process.complete == true
    assert completed_process.data == %{value: 1}
  end

  test "correcting bad data and re-executing" do
    # Will cause a process restart due to adding 1 to "foobar"
    PMS.clear_then_load_process_models(TestModels.get_testing_process_models())
    data = %{value: "foobar"}
    {:ok, ppid, uid} = PE.start_process(:increment_by_one_process, data)
    PE.execute(ppid)

    Process.monitor(ppid)
    assert_receive({:DOWN, _ref, :process, _object, _reason})
    Process.sleep(100)

    # Process will have been restarted. Get new pid.
    new_pid = PS.get_process_ppid(uid)
    # Correct data
    PE.set_data(new_pid, %{value: 1})
    PE.execute(new_pid)

    Process.monitor(new_pid)
    assert_receive({:DOWN, _ref, :process, _object, _reason})

    completed_process = PS.get_completed_process(uid)
    assert completed_process.complete == true
    assert completed_process.data == %{value: 2}
  end

  test "two increment tasks in a row" do
    PMS.clear_then_load_process_models(TestModels.get_testing_process_models())
    data = %{value: 0}
    {:ok, ppid, uid} = PE.start_process(:increment_by_one_twice_process, data)
    catch_exit(PE.execute_and_wait(ppid))

    completed_process = PS.get_completed_process(uid)
    assert completed_process.complete == true
    assert completed_process.data == %{value: 3}
  end

  test "Three increment tasks in a row" do
    PMS.clear_then_load_process_models(TestModels.get_testing_process_models())
    data = %{value: 0}
    {:ok, ppid, uid} = PE.start_process(:three_increment_by_one_process, data)
    catch_exit(PE.execute_and_wait(ppid))

    completed_process = PS.get_completed_process(uid)
    assert completed_process.complete == true
    assert completed_process.data == %{value: 6}
    assert completed_process.open_tasks == %{}
  end
end
