defmodule Mozart.Dsl.ApproveLoan do
  use Mozart.Dsl.BpmProcess

    defprocess "Approve Loan" do
      call_service("Check Credit Score")
      call_service("Perform Loan Processing")
      call_service("Perform Underwriting")
    end

    defprocess "Process Loan" do
      call_service("Check Credit Score")
      call_service("Perform Loan Processing")
      call_service("Perform Underwriting")
    end
end
