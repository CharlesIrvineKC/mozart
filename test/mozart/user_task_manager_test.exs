defmodule Mozart.UserTaskManagerTest do
  use ExUnit.Case

  alias Mozart.ProcessManager
  alias Mozart.UserTaskManager
  alias Mozart.Data.Task
  alias Mozart.Util

  setup do
    {:ok, _pid} = UserTaskManager.start_link([])
    {:ok, _pid} = ProcessManager.start_link(nil)
    Enum.each(Util.get_testing_process_models(), fn model -> ProcessManager.load_process_model(model) end)
    %{ok: nil}
  end

  test "initial tasks is empty" do
    assert UserTaskManager.get_user_tasks() == []
  end

  test "get tasks for groups" do
    task = %Task{assigned_groups: ["admin"]}
    UserTaskManager.insert_user_task(task)
    tasks = UserTaskManager.get_tasks_for_groups(["foo"])
    assert tasks == []

    task = %Task{assigned_groups: ["foo"]}
    UserTaskManager.insert_user_task(task)
    tasks = UserTaskManager.get_tasks_for_groups(["foo"])
    assert tasks != []
  end

  test "add a human task" do
    task = %Task{assigned_groups: ["admin"]}
    UserTaskManager.insert_user_task(task)
    assert UserTaskManager.get_user_tasks() != []
  end

  test "complete a user task" do
    model = ProcessManager.get_process_model(:user_task_process_model)
    ProcessManager.load_process_model(model)
    process_id = ProcessManager.start_process(:user_task_process_model, %{foo: :foo})
    process_pid = ProcessManager.get_process_ppid(process_id)


  end
end
