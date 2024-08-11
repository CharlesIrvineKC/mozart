defmodule Mozart.BpmServiceTest do
  use ExUnit.Case
  use Mozart.BpmProcess

  alias Mozart.ProcessEngine, as: PE
  alias Mozart.ProcessService, as: PS

  defprocess "prototype then user task" do
    prototype_task("a prototype task")
    user_task("add one to x", groups: "admin", outputs: "x")
  end

  test "prototype then user task" do
    PS.clear_state()
    load()
    data = %{foo: :bar}

    {:ok, ppid, _uid, _business_key} = PE.start_process("prototype then user task", data)
    PE.execute(ppid)
    Process.sleep(100)

    IO.inspect(PE.get_state(ppid))

  end
end
