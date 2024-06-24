defmodule Mozart.Dsl.TestProcesses do
  use Mozart.Dsl.BpmProcess

  defprocess "single user task process" do
    user_task("add one to x", groups: "admin")
  end

  rule_table = """
      F     income      || status
      1     > 50000     || approved
      2     <= 49999    || declined
      """

  defprocess "single rule task process" do
    rule_task("loan decision", inputs: "income", rule_table: rule_table)
  end

end
