defmodule Mozart.Dsl.TestProcesses do
  use Mozart.Dsl.BpmProcess

  defprocess "single user task process" do
    user_task("add one to x", groups: "admin")
  end
  
end
