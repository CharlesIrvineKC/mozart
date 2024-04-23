defmodule Mozart.UserTaskServiceTest do
  use ExUnit.Case

  alias Mozart.ProcessEngine, as: PE
  alias Mozart.ProcessService, as: PS
  alias Mozart.ProcessModelService, as: PMS
  alias Mozart.UserTaskService
  alias Mozart.Data.Task
  alias Mozart.Data.User
  alias Mozart.Util

  setup do
    {:ok, _pid} = UserTaskService.start_link([])
    {:ok, _pid} = PS.start_link(nil)
    {:ok, _pid} = PMS.start_link(nil)
    Enum.each(Util.get_testing_process_models(), fn model -> PMS.load_process_model(model) end)
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
    assert UserTaskService.get_tasks_for_groups(user.groups) != []
    UserTaskService.get_user_tasks()

    PE.complete_user_task(process_pid, :foo, %{foobar: "foobar"})
    assert PE.get_data(process_pid) == %{foobar: "foobar", foo: :foo}
    assert PE.is_complete(process_pid) == true
  end
end
