defmodule Mozart.ProcessServiceTest do
  use ExUnit.Case
  use Mozart.BpmProcess

  alias Mozart.ProcessEngine, as: PE
  alias Mozart.ProcessService, as: PS

  defprocess "process with one user task" do
    user_task("a user task", group: "admin")
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

end
