defmodule Mozart.TaskManagerTest do
  use ExUnit.Case

  alias Mozart.UserTaskManager
  alias Mozart.Data.Task

  setup do
    UserTaskManager.start_link([])
    %{ok: nil}
  end

  test "initial tasks is empty" do
    assert UserTaskManager.get_user_tasks() == []
  end

  test "get tasks for groups" do
    task = %Task{assigned_groups: ["admin"]}
    UserTaskManager.insert_user_task(task)
    tasks = UserTaskManager.get_tasks_from_groups(["foo"])
    assert tasks == []

    task = %Task{assigned_groups: ["foo"]}
    UserTaskManager.insert_user_task(task)
    tasks = UserTaskManager.get_tasks_from_groups(["foo"])
    assert tasks != []
  end

  test "add a human task" do
    task = %Task{assigned_groups: ["admin"]}
    UserTaskManager.insert_user_task(task)
    assert UserTaskManager.get_user_tasks() != []
  end
end
