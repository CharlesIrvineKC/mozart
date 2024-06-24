defmodule Mozart.DslProcessEngineTest do
  use ExUnit.Case

  alias Mozart.ProcessEngine, as: PE
  alias Mozart.ProcessService, as: PS
  alias Mozart.Dsl.TestProcesses, as: TP

  test "single user task process" do
    PS.clear_state()
    PS.load_process_models(TP.get_processes())
    data = %{}

    {:ok, ppid, _uid, _process_key} = PE.start_process("single user task process", data)
    PE.execute(ppid)
    Process.sleep(100)

    assert PE.is_complete(ppid) == false
  end

  test "single rule task process" do
    PS.clear_state()
    PS.load_process_models(TP.get_processes())
    data = %{income: 3000}

    {:ok, ppid, uid, _process_key} = PE.start_process("single rule task process", data)
    PE.execute(ppid)
    Process.sleep(100)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{income: 3000, status: "declined"}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 1
  end
end
