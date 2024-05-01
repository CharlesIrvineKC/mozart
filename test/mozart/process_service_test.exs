defmodule Mozart.ProcessServiceTest do
  use ExUnit.Case

  alias Mozart.ProcessModelService, as: PMS
  alias Mozart.UserService, as: US
  alias Mozart.ProcessEngine, as: PE
  alias Mozart.ProcessService, as: PS
  alias Mozart.Util
  alias Mozart.Data.User

  setup do
    PMS.clear_then_load_process_models(Util.get_testing_process_models())
    PS.clear_user_tasks()
  end

  setup_all do
    US.insert_user(%User{name: "crirvine", groups: ["admin"]})
  end

  test "get user tasks for person" do
    tasks = PS.get_user_tasks("crirvine")
    assert tasks == []
  end

  test "assign a task to a user" do
    PMS.clear_then_load_process_models(Util.get_testing_process_models())
    PS.start_process(:one_user_task_process, %{value: 1})
    [task] = PS.get_user_tasks("crirvine")
    PS.assign_user_task(task, "crirvine")
    [task] = PS.get_user_tasks("crirvine")
    assert task.assignee == "crirvine"
  end

  test "start a process engine" do
    PMS.clear_then_load_process_models(Util.get_parallel_process_models())
    pid = PS.start_process(:parallel_process_model, %{value: 1})
    assert PE.is_complete(pid) == true
    assert PE.get_data(pid) == %{value: 1, final: :final, foo: :foo, bar: :bar, foo_bar: :foo_bar}
  end
end
