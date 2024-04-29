defmodule Mozart.UserTaskServiceTest do
  use ExUnit.Case

  alias Mozart.ProcessEngine, as: PE
  alias Mozart.ProcessModelService, as: PMS
  alias Mozart.UserTaskService, as: UTS
  alias Mozart.Data.Task
  alias Mozart.Data.User
  alias Mozart.Util

  setup do
    PMS.clear_then_load_process_models(Util.get_testing_process_models())
    UTS.clear_user_tasks()
    %{ok: nil}
  end

  test "initial tasks is empty" do
    assert UTS.get_user_tasks() == []
  end

  test "get tasks for groups" do
    task = %Task{assigned_groups: ["admin"]}
    UTS.insert_user_task(task)
    tasks = UTS.get_tasks_for_groups(["foo"])
    assert tasks == []

    task = %Task{assigned_groups: ["foo"]}
    UTS.insert_user_task(task)
    tasks = UTS.get_tasks_for_groups(["foo"])
    assert tasks != []
  end

  test "add a human task" do
    task = %Task{assigned_groups: ["admin"]}
    UTS.insert_user_task(task)
    assert UTS.get_user_tasks() != []
  end

  test "complete a user task" do
    model = PMS.get_process_model(:user_task_process_model)
    {:ok, process_pid} = PE.start_link(model, %{foo: :foo})

    assert PE.is_complete(process_pid) == false

    PE.complete_user_task(process_pid, :foo, %{foobar: "foobar"})
    assert PE.is_complete(process_pid) == true
  end

  test "complete a user task with specified user" do
    model = PMS.get_process_model(:user_task_process_model)
    {:ok, process_pid} = PE.start_link(model, %{foo: :foo})

    assert PE.is_complete(process_pid) == false

    user = %User{name: "cirvine", groups: ["admin"]}
    assert UTS.get_tasks_for_groups(user.groups) != []
    UTS.get_user_tasks()

    PE.complete_user_task(process_pid, :foo, %{foobar: "foobar"})
    assert PE.get_data(process_pid) == %{foobar: "foobar", foo: :foo}
    assert PE.is_complete(process_pid) == true
  end
end
