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
end
