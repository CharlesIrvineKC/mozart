defmodule Mozart.PersistenceTest do
  use ExUnit.Case
  use Mozart.BpmProcess

  alias Mozart.ProcessEngine, as: PE
  alias Mozart.ProcessService, as: PS

  def_choice_type("Decision", choices: "Yes, No")

  defprocess "choice process" do
    user_task("a user task", groups: "Admin", outputs: "Decision")
  end

  test "choice process" do
    PS.clear_state()
    load()

    {:ok, ppid, _uid, _business_key} = PE.start_process("choice process", %{})
    PE.execute(ppid)
    Process.sleep(100)

    type = PS.get_type("Decision")
    IO.inspect(type, label: "** type **")

  end

  def_bpm_application("one prototype task process", main: "one prototype task process", data: "")

  defprocess "one prototype task process" do
    prototype_task("a prototype task")
  end

  test "one prototype task process" do
    PS.clear_state()
    load()

    {:ok, ppid, _uid, _business_key} = PE.start_process("one prototype task process", %{})
    PE.execute(ppid)
    Process.sleep(100)

    IO.inspect(PS.get_persisted_processes(), label: "*** process state ***")
  end

  defprocess "one user task process" do
    user_task("add one to x 1", groups: "admin", outputs: "x")
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

    IO.inspect(PS.get_persisted_processes(), label: "*** process state ***")
  end

end
