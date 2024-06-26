defmodule Mozart.Dsl.ApproveLoan do
  use Mozart.Dsl.BpmProcess

    defprocess "Approve Loan" do
      script_task("Check Credit Score", inputs: "x", fn: "x = x = 1")
      user_task("Do Underwriting", groups: "admin")
      subprocess_task("Perform Loan Sutup", model: "Perform Loan Sutup Model")
    end

    defprocess "Perform Loan Sutup Model" do
      service_task("Send Approval Notice", module: "Test", function: "foo", inputs: "customer_info")
    end
end
