defmodule Mozart.ProcessServiceTest do
  use ExUnit.Case

  alias Mozart.ProcessModelService, as: PMS
  alias Mozart.UserService, as: US
  alias Mozart.ProcessService, as: PS
  alias Mozart.ProcessEngine, as: PE
  alias Mozart.TestModels
  alias Mozart.Data.User

  setup do
    PS.clear_user_tasks()
  end

  setup_all do
    US.insert_user(%User{name: "crirvine", groups: ["admin"]})
  end

  test "get user tasks for person" do
    tasks = PS.get_user_tasks("crirvine")
    assert tasks == []
  end

  test "complete a user task" do
    PMS.clear_then_load_process_models(TestModels.get_testing_process_models())
    data = %{value: 0}
    {:ok, ppid, uid} = PE.start_supervised_pe(:user_task_process_model, data)
    PE.execute(ppid)

    [task_instance] = IO.inspect(Map.values(PE.get_task_instances(ppid)))

    PS.complete_user_task(ppid, task_instance.uid, %{user_task_complete: true})
    Process.sleep(50)
    assert PS.get_completed_process(uid) != nil
  end

  test "assign a task to a user" do
    PMS.clear_then_load_process_models(TestModels.get_testing_process_models())
    {:ok, ppid, _uid} = PE.start_supervised_pe(:one_user_task_process, %{value: 1})
    PE.execute(ppid)
    Process.sleep(10)
    [task] = PS.get_user_tasks("crirvine")
    PS.assign_user_task(task, "crirvine")
    [task] = PS.get_user_tasks("crirvine")
    assert task.assignee == "crirvine"
  end

  test "start a process engine" do
    PMS.clear_then_load_process_models(TestModels.get_parallel_process_models())
    {:ok, ppid, uid} = PE.start_supervised_pe(:parallel_process_model, %{value: 1})
    PE.execute(ppid)
    Process.sleep(10)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{value: 1, final: :final, foo: :foo, bar: :bar, foo_bar: :foo_bar}
    assert completed_process.complete == true
  end
end
