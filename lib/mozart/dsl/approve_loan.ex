defmodule Mozart.Dsl.ApproveLoan do
  use Mozart.Dsl.BpmProcess

    defprocess "Approve Loan" do
      script_task("Check Credit Score", inputs: "x", fn: "x = x = 1")
      user_task("Do Underwriting", groups: "admin")
      call_subprocess("Perform Loan Sutup", model: "Perform Loan Sutup Model")
    end

    defprocess "Perform Loan Sutup Model" do
      script_task("Send Approval Notice", inputs: "customer_info", fn: "x = x = 1")
    end
end
