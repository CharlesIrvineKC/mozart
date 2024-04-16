defmodule Mozart.UserTaskServiceTest do
  use ExUnit.Case

  alias Mozart.ProcessService
  alias Mozart.UserTaskService
  alias Mozart.Data.Task
  alias Mozart.Util

  setup do
    {:ok, _pid} = UserTaskService.start_link([])
    {:ok, _pid} = ProcessService.start_link(nil)
    Enum.each(Util.get_testing_process_models(), fn model -> ProcessService.load_process_model(model) end)
    %{ok: nil}
  end

  test "initial tasks is empty" do
    assert UserTaskService.get_user_tasks() == []
  end

  test "get tasks for groups" do
    task = %Task{assigned_groups: ["admin"]}
    UserTaskService.insert_user_task(task)
    tasks = UserTaskService.get_tasks_for_groups(["foo"])
    assert tasks == []

    task = %Task{assigned_groups: ["foo"]}
    UserTaskService.insert_user_task(task)
    tasks = UserTaskService.get_tasks_for_groups(["foo"])
    assert tasks != []
  end

  test "add a human task" do
    task = %Task{assigned_groups: ["admin"]}
    UserTaskService.insert_user_task(task)
    assert UserTaskService.get_user_tasks() != []
  end

  test "complete a user task" do
    model = ProcessService.get_process_model(:user_task_process_model)
    ProcessService.load_process_model(model)
    process_id = ProcessService.start_process(:user_task_process_model, %{foo: :foo})
    process_pid = ProcessService.get_process_ppid(process_id)


  end
end
