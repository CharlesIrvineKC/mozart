defmodule Mozart.DslProcessEngineTest do
  use ExUnit.Case
  use Mozart.Dsl.BpmProcess

  alias Mozart.ProcessEngine, as: PE
  alias Mozart.ProcessService, as: PS

  defprocess "single user task process" do
    user_task("add one to x", groups: "admin")
  end

  test "single user task process" do
    PS.clear_state()
    PS.load_process_models(get_processes())
    data = %{}

    {:ok, ppid, _uid, _process_key} = PE.start_process("single user task process", data)
    PE.execute(ppid)
    Process.sleep(100)

    assert PE.is_complete(ppid) == false
  end

  defprocess "three user task process" do
    user_task("1", groups: "admin")
    user_task("2", groups: "admin")
    user_task("3", groups: "admin")
  end

  test "three user task process" do
    PS.clear_state()
    PS.load_process_models(get_processes())
    data = %{}

    {:ok, ppid, _uid, _process_key} = PE.start_process("three user task process", data)
    PE.execute(ppid)
    Process.sleep(100)

    assert PE.is_complete(ppid) == false
    process = get_process("three user task process")
  end

  rule_table = """
  F     income      || status
  1     > 50000     || approved
  2     <= 49999    || declined
  """

  defprocess "single rule task process" do
    rule_task("loan decision", inputs: "income", rule_table: rule_table)
  end

  test "single rule task process" do
    PS.clear_state()
    PS.load_process_models(get_processes())
    data = %{income: 3000}

    {:ok, ppid, uid, _process_key} = PE.start_process("single rule task process", data)
    PE.execute(ppid)
    Process.sleep(100)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{income: 3000, status: "declined"}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 1
  end

  def x_less_than_y(data) do
    data.x < data.y
  end

  def x_greater_or_equal_y(data) do
    data.x >= data.y
  end

  defprocess "two case process" do
    case_task("yes or no", [
      case_i &__MODULE__.x_less_than_y/1 do
        user_task("1", groups: "admin")
        user_task("2", groups: "admin")
      end,
      case_i &__MODULE__.x_greater_or_equal_y/1 do
        user_task("3", groups: "admin")
        user_task("4", groups: "admin")
      end
    ])
  end

  test "two case process" do
    PS.clear_state()
    PS.load_process_models(get_processes())
    data = %{x: 1, y: 2}

    {:ok, ppid, _uid, _process_key} = PE.start_process("two case process", data)
    PE.execute(ppid)
    Process.sleep(100)

    assert PE.is_complete(ppid) == false
    process = get_process("two case process")
    IO.inspect(process)
    #IO.inspect(PE.get_state(ppid))
  end
end
