defmodule Mozart.DslProcessEngineTest do
  use ExUnit.Case

  alias Mozart.ProcessEngine, as: PE
  alias Mozart.ProcessService, as: PS
  alias Mozart.Dsl.TestProcesses, as: TP

  test "single script process" do
    PS.clear_state()
    PS.load_process_models(TP.get_processes())
    data = %{}

    {:ok, ppid, _uid, _process_key} = PE.start_process("single user task process", data)
    PE.execute(ppid)
    Process.sleep(100)

    assert PE.is_complete(ppid) == false
  end
end
