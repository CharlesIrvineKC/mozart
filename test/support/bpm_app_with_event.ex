defmodule BpmAppWithEvent do
  @moduledoc false
  use Mozart.BpmProcess

  def event_selector(message) do
    case message do
      :exit_user_task -> true
      _ -> nil
    end
  end

  defprocess "exit a user task 1" do
    user_task("user task 1", groups: "admin", outputs: "tbd")
  end

  defevent "exit loan decision 1",
    process: "exit a user task 1",
    exit_task: "user task 1",
    selector: &BpmAppWithEvent.event_selector/1 do
      prototype_task("event 1 prototype task 1")
      prototype_task("event 1 prototype task 2")
  end

  defprocess "exit a user task 2" do
    user_task("user task 2", groups: "admin", outputs: "tbd")
  end

  defevent "exit loan decision 2",
    process: "exit a user task 2",
    exit_task: "user task 2",
    selector: &BpmAppWithEvent.event_selector/1 do
      prototype_task("event 2 prototype task 1")
      prototype_task("event 2 prototype task 2")
  end

end
