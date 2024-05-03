defmodule Mozart.ProcessEngineTest do
  use ExUnit.Case

  alias Mozart.Util
  alias Mozart.ProcessEngine, as: PE
  alias Mozart.ProcessModelService, as: PMS
  alias Mozart.ProcessService, as: PS

  @moduletag timeout: :infinity

  def load_process_models(models) do
    Enum.each(models, fn model -> PMS.load_process_model(model) end)
  end

  # test "call an external service" do
  #   load_process_models(Util.call_exteral_services())
  #   model = PMS.get_process_model(:call_external_services)
  #   data = %{}

  #   {:ok, _ppid, uid} = PE.start(model, data)
  #   Process.sleep(10)
  #   assert PS.get_completed_process(uid) != nil
  # end

  test "complex process model" do
    load_process_models(Util.get_complex_process_models())
    data = %{value: 1}

    {:ok, _ppid, uid} = PE.start(:call_process_model, data)
    Process.sleep(10)
    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{value: 7}
    assert completed_process.complete == true
  end

  test "start server and get id" do
    load_process_models(Util.get_testing_process_models())
    data = %{foo: "foo"}

    {:ok, _ppid, uid} = PE.start(:simple_process_model, data)
    Process.sleep(10)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{foo: "foo", bar: :bar}
    assert completed_process.complete == true
  end

  test "execute process with subprocess" do
    load_process_models(Util.get_testing_process_models())
    data = %{value: 1}
    {:ok, _ppid, _uid} = PE.start(:simple_call_process_model, data)
  end

  test "execute process with service subprocess" do
    load_process_models(Util.get_testing_process_models())
    data = %{value: 1}
    {:ok, _ppid, uid} = PE.start(:simple_call_service_process_model, data)
    Process.sleep(10)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{value: 1, service: :service}
    assert completed_process.complete == true
  end

  test "execute process with choice and join" do
    load_process_models(Util.get_parallel_process_models())
    data = %{value: 1}
    {:ok, _ppid, uid} = PE.start(:parallel_process_model, data)
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
    load_process_models(Util.get_testing_process_models())
    data = %{value: 1}
    {:ok, _ppid, uid} = PE.start(:choice_process_model, data)
    Process.sleep(10)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{value: 1, foo: :foo}
    assert completed_process.complete == true
  end

  test "execute process with choice returning :bar" do
    load_process_models(Util.get_testing_process_models())
    data = %{value: 11}
    {:ok, _ppid, uid} = PE.start(:choice_process_model, data)
    Process.sleep(10)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{value: 11, bar: :bar}
    assert completed_process.complete == true
  end

  test "one user task" do
    load_process_models(Util.get_testing_process_models())
    data = %{value: 0}
    {:ok, ppid, _uid} = PE.start(:user_task_process_model, data)
    Process.sleep(10)

    assert PE.get_data(ppid) == %{value: 0}
    task_instances = PE.get_task_instances(ppid)
    assert Enum.map(task_instances, fn t_i -> t_i.name end) == [:foo]
    assert PE.is_complete(ppid) == false
  end

  test "complete one user task" do
    load_process_models(Util.get_testing_process_models())
    data = %{value: 0}
    {:ok, ppid, uid} = PE.start(:user_task_process_model, data)

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
    load_process_models(Util.get_testing_process_models())
    data = %{value: 0}
    {:ok, ppid, uid} = PE.start(:user_task_then_service, data)
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
    load_process_models(Util.get_testing_process_models())
    data = %{value: 0}
    {:ok, ppid, uid} = PE.start(:service_then_user_task, data)
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
    load_process_models(Util.get_testing_process_models())
    data = %{foo: :foo}
    {:ok, _ppid, uid} = PE.start(:simple_process_model, data)
    Process.sleep(10)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.complete == true
    assert completed_process.model_name ==:simple_process_model
  end

  test "set and get data" do
    load_process_models(Util.get_testing_process_models())
    data = %{value: 1}
    {:ok, _ppid, uid} = PE.start(:simple_process_model, data)
    Process.sleep(10)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.complete == true
    assert completed_process.data == %{value: 1, bar: :bar}
  end

  test "get process model open tasks" do
    load_process_models(Util.get_testing_process_models())
    data = %{value: 1}
    {:ok, _ppid, uid} = PE.start(:simple_process_model, data)
    Process.sleep(10)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.complete == true
    assert completed_process.data == %{value: 1, bar: :bar}
  end

  test "complete increment by one task" do
    load_process_models(Util.get_testing_process_models())
    data = %{value: 0}
    {:ok, _ppid, uid} = PE.start(:increment_by_one_process, data)
    Process.sleep(10)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.complete == true
    assert completed_process.data == %{value: 1}
  end

  test "two increment tasks in a row" do
    load_process_models(Util.get_testing_process_models())
    data = %{value: 0}
    {:ok, _ppid, uid} = PE.start(:increment_by_one_twice_process, data)
    Process.sleep(10)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.complete == true
    assert completed_process.data == %{value: 3}
  end

  test "Three increment tasks in a row" do
    load_process_models(Util.get_testing_process_models())
    data = %{value: 0}
    {:ok, _ppid, uid} = PE.start(:three_increment_by_one_process, data)
    Process.sleep(10)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.complete == true
    assert completed_process.data == %{value: 6}
    assert completed_process.task_instances == []
  end
end
