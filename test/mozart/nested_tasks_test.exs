defmodule Mozart.NestedTasksTest do
  use ExUnit.Case
  use Mozart.BpmProcess

  alias Mozart.ProcessEngine, as: PE
  alias Mozart.ProcessService, as: PS

  def continue_outer(data) do
    data["Outer Count"] < 3
  end

  def continue_inner(data) do
    data["Inner Count"] < 3
  end

  def add_1_to_outer_count(data) do
    %{"Outer Count" => data["Outer Count"] + 1}
  end

  def add_1_to_inner_count(data) do
    %{"Inner Count" => data["Inner Count"] + 1}
  end

  defprocess "nested repeat process" do
    repeat_task "outer repeat task", condition: :continue_outer do
      prototype_task("outer prototype task")
      service_task("add one to outer count", function: :add_1_to_outer_count, inputs: "Outer Count")
      repeat_task "inner repeat task", condition: :continue_inner do
        prototype_task("inner prototype task")
        service_task("add one to inner count", function: :add_1_to_inner_count, inputs: "Inner Count")
      end
    end
  end

  test "nested repeat process" do
    PS.clear_state()
    load()
    data = %{"Outer Count" => 0, "Inner Count" => 0}

    {:ok, ppid, uid, _business_key} = PE.start_process("nested repeat process", data)
    PE.execute(ppid)
    Process.sleep(200)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 5
  end
end
