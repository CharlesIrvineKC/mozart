defmodule Mozart.TaskManagerTest do
  use ExUnit.Case

  alias Mozart.TaskManager
  alias Mozart.Data.Task

  setup do
    TaskManager.start_link([])
    %{ok: nil}
  end

  test "initial tasks is empty" do
    assert TaskManager.get_user_tasks() == []
  end

  test "get tasks for groups" do
    task = %Task{assigned_groups: ["admin"]}
    TaskManager.insert_user_task(task)
    tasks = TaskManager.get_tasks_from_groups(["foo"])
    assert tasks == []

    task = %Task{assigned_groups: ["foo"]}
    TaskManager.insert_user_task(task)
    tasks = TaskManager.get_tasks_from_groups(["foo"])
    assert tasks != []
  end

  test "add a human task" do
    task = %Task{assigned_groups: ["admin"]}
    TaskManager.insert_user_task(task)
    assert TaskManager.get_user_tasks() != []
  end
end
