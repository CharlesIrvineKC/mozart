defmodule Mozart.ProcessServiceTest do
  use ExUnit.Case

  alias Mozart.UserService, as: US
  alias Mozart.ProcessService, as: PS
  alias Mozart.ProcessEngine, as: PE
  alias Mozart.ProcessModels.TestModels
  alias Mozart.Data.User

  setup do
    PS.clear_user_tasks()
  end

  setup_all do
    US.insert_user(%User{name: "crirvine", groups: ["admin"]})
  end

  test "get user tasks for person" do
    PS.clear_user_tasks()
    tasks = PS.get_user_tasks_for_user("crirvine")
    assert tasks == []
  end

  test "complete a user task" do
    PS.clear_then_load_process_models(TestModels.get_testing_process_models())
    data = %{value: 0}
    {:ok, ppid, uid} = PE.start_process(:user_task_process_model, data)
    PE.execute_and_wait(ppid)

    [task_instance] = Map.values(PE.get_open_tasks(ppid))

    PS.complete_user_task(ppid, task_instance.uid, %{user_task_complete: true})
    Process.sleep(50)

    assert PS.get_completed_process(uid) != nil
  end

  test "assign a task to a user" do
    PS.clear_then_load_process_models(TestModels.get_testing_process_models())
    PS.clear_user_tasks()
    {:ok, ppid, _uid} = PE.start_process(:one_user_task_process, %{value: 1})
    PE.execute(ppid)
    Process.sleep(10)
    [task] = PS.get_user_tasks_for_user("crirvine")
    PS.assign_user_task(task, "crirvine")
    [task] = PS.get_user_tasks_for_user("crirvine")
    assert task.assignee == "crirvine"
  end

  test "start a process engine" do
    PS.clear_then_load_process_models(TestModels.get_parallel_process_models())
    {:ok, ppid, uid} = PE.start_process(:parallel_process_model, %{value: 1})
    PE.execute(ppid)
    Process.sleep(10)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{value: 1, final: :final, foo: :foo, bar: :bar, foo_bar: :foo_bar}
    assert completed_process.complete == true
  end
end
