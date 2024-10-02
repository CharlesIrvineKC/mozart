defmodule Mozart.ProcessServiceTest do
  use ExUnit.Case
  use Mozart.BpmProcess

  alias Mozart.ProcessEngine, as: PE
  alias Mozart.ProcessService, as: PS

  defprocess "process with one user task" do
    user_task("a user task", group: "admin")
    prototype_task("a prototype test")
  end

  defprocess "process with subprocess" do
    subprocess_task("subprocess task", process: "process with one user task")
  end

  test "process with one user task" do
    PS.clear_state()
    load()
    data = %{}

    {:ok, ppid, _uid, _business_key} =
      PE.start_process("process with one user task", data)

    PE.execute(ppid)
    Process.sleep(100)

    user_task = hd(PS.get_user_tasks())

    assert user_task.assigned_group == "admin"
    assert PS.get_user_tasks_for_group("admin") == [user_task]
  end

  test "get process source code" do
    get_process("process with one user task")
  end

  test "get active processes" do
    PS.clear_state()
    load()
    data = %{}

    {:ok, ppid1, _uid, _business_key} =
      PE.start_process("process with one user task", data)

    PE.execute(ppid1)

    {:ok, ppid2, _uid, _business_key} =
      PE.start_process("process with one user task", data)

    PE.execute(ppid2)

    Process.sleep(100)

    assert length(Map.values(PS.get_active_processes())) == 2
  end

  test "get open process tasks" do
    PS.clear_state()
    load()
    data = %{}

    {:ok, ppid, uid, _business_key} =
      PE.start_process("process with subprocess", data)

    PE.execute(ppid)
    Process.sleep(100)

    assert length(PS.get_open_tasks(uid)) == 2
  end

  defprocess "process with two prototype tasks" do
    prototype_task("a prototype test 1")
    prototype_task("a prototype test 2")
  end

  defprocess "process with prototype subprocess" do
    subprocess_task("a subprocess task", process: "process with two prototype tasks")
    user_task("wait user task", groups: "Admin")
  end

  test "get completed tasks" do
    PS.clear_state()
    load()
    data = %{}

    {:ok, ppid, uid, _business_key} =
      PE.start_process("process with prototype subprocess", data)

    PE.execute(ppid)
    Process.sleep(100)

    completed_tasks = PS.get_completed_tasks(uid)

    assert length(completed_tasks) == 3
  end

  test "get process state" do
    PS.clear_state()
    load()
    data = %{}

    {:ok, ppid, uid, _business_key} =
      PE.start_process("process with prototype subprocess", data)

    PE.execute(ppid)
    Process.sleep(100)

    process_state = PS.get_process_state(uid)

    assert length(process_state.completed_tasks) == 3
  end

  defprocess "process with one user task 2" do
    user_task("user task in simple process", groups: "foobar")
  end

  test "test for active processes" do
    PS.clear_state()
    load()
    data = %{}

    {:ok, ppid, uid, _business_key} = PE.start_process("process with one user task 2", data)
    PE.execute(ppid)

    Process.sleep(100)

    assert PS.get_process_state(uid) != nil
  end
end
