defmodule Mozart.UserTaskServiceTest do
  use ExUnit.Case

  alias Mozart.ProcessEngine
  alias Mozart.ProcessService
  alias Mozart.UserTaskService
  alias Mozart.Data.Task
  alias Mozart.Data.User
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
    process_uid = ProcessService.start_process(:user_task_process_model, %{foo: :foo})

    process_pid = ProcessService.get_process_ppid(process_uid)
    assert ProcessEngine.is_complete(process_pid) == false

    ProcessEngine.complete_user_task(process_pid, :foo, %{foobar: "foobar"})
    assert ProcessEngine.is_complete(process_pid) == true
  end

  test "complete a user task with specified user" do
    model = ProcessService.get_process_model(:user_task_process_model)
    ProcessService.load_process_model(model)
    process_uid = ProcessService.start_process(:user_task_process_model, %{foo: :foo})

    process_pid = ProcessService.get_process_ppid(process_uid)
    assert ProcessEngine.is_complete(process_pid) == false

    user = %User{name: "cirvine", groups: ["admin"]}
    assert UserTaskService.get_tasks_for_groups(user.groups) != []
    UserTaskService.get_user_tasks()

    ProcessEngine.complete_user_task(process_pid, :foo, %{foobar: "foobar"})
    assert ProcessEngine.get_data(process_pid) == %{foobar: "foobar", foo: :foo}
    assert ProcessEngine.is_complete(process_pid) == true
  end
end
