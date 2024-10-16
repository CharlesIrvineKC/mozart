defmodule Mozart.ProcessEngineUnitTest do
  use ExUnit.Case
  @moduletag timeout: :infinity

  use Mozart.BpmProcess

  alias Mozart.ProcessService, as: PS
  alias Mozart.Data.ExecutionFrame
  alias Mozart.Data.ProcessState

  import Mozart.ProcessEngine

  defprocess "simple prototype process" do
    prototype_task("a prototype task")
  end

  defp set_state(process) do
    %ProcessState{
      top_level_process: process,
      start_time: DateTime.utc_now(),
      execution_frames: [%ExecutionFrame{process: process, data: %{}}]
    }
  end

  test "simple prototype process" do
    PS.clear_state()
    load()

    state = set_state("simple prototype process")
    model = get_process("simple prototype process")
    state = create_next_tasks(state, model.initial_task)

    execute_process(state)
  end

  defprocess "process with documented user task" do
    user_task("a user task",
    documentation: "Now is the time for all good men to come to the aid of their country.")
  end

  test "process with documented user task" do
    assert get_process("process with documented user task")
           |> Map.get(:tasks)
           |> Enum.find(fn t -> t.name == "a user task" end)
           |> Map.get(:documentation)
    === "Now is the time for all good men to come to the aid of their country."
  end

  def return_true(_data) do
    true
  end

  defprocess "case process calling subprocess" do
    prototype_task("initial prototype task")

    case_task "case task" do
      case_i :return_true do
        subprocess_task("perform subprocess task", process: "a subprocess")
        # prototype_task("single case_i prototype task")
      end
    end
  end

  defprocess "a subprocess" do
    prototype_task("subprocess prototype task 1")
    prototype_task("subprocess prototype task 2")
  end

  test "case process calling subprocess" do
    PS.clear_state()
    load()

    state = set_state("case process calling subprocess")
    model = get_process("case process calling subprocess")
    state = create_next_tasks(state, model.initial_task)

    state = execute_process(state)

    assert state.completed_tasks |> length() == 5
    assert state.execution_frames |> hd() |> Map.get(:open_tasks) == %{}
  end
end
