defmodule Mozart.PersistenceTest do
  use ExUnit.Case
  use Mozart.BpmProcess

  alias Mozart.ProcessEngine, as: PE
  alias Mozart.ProcessService, as: PS

  def_choice_type("Decision", choices: "Yes, No")

  defprocess "choice process" do
    user_task("a user task", group: "Admin", outputs: "Decision")
  end

  test "choice process" do
    PS.clear_state()
    load()

    {:ok, ppid, _uid, _business_key} = PE.start_process("choice process", %{})
    PE.execute(ppid)
    Process.sleep(100)

    PS.get_type("Decision")
  end

  defprocess "one prototype task process" do
    prototype_task("a prototype task")
  end

  test "one prototype task process" do
    PS.clear_state()
    load()

    {:ok, ppid, _uid, _business_key} = PE.start_process("one prototype task process", %{})
    PE.execute(ppid)
    Process.sleep(100)
  end

  defprocess "one user task process" do
    user_task("add one to x 1", group: "admin", outputs: "x")
  end

  test "one user task process" do
    PS.clear_state()
    load()

    {:ok, ppid, _uid, _business_key} = PE.start_process("one user task process", %{})
    PE.execute(ppid)
    Process.sleep(100)

    {:ok, ppid, _uid, _business_key} = PE.start_process("one user task process", %{})
    PE.execute(ppid)
    Process.sleep(100)
  end
end
