defmodule Opera.Processes.HomeLoanApp do
  @moduledoc false
  use Mozart.BpmProcess

  def_bpm_application("Home Loan Process", main: "Home Loan", data: "Customer Name,Income,Debt")

  def pre_approved(data) do
    data["Pre Approval"] == "Approved"
  end

  def pre_approval_declined(data) do
   data["Pre Approval"] == "Declined"
  end

  def_choice_type("Pre Approval", choices: "Approved, Declined")
  def_choice_type("Loan Verified", choices: "Pass, Fail")
  def_choice_type("Loan Approved", choices: "Approved, Declined")

  defprocess "Home Loan" do
    user_task("Perform Pre-Approval", groups: "credit", outputs: "Pre Approval")
    case_task "Route on Pre-Approcal Completion" do
      case_i :pre_approved do
        user_task("Receive Mortage Application", groups: "credit", outputs: "Purchase Price")
        user_task("Process Loan", groups: "credit", outputs: "Loan Verified")
        subprocess_task("Perform Loan Evaluation", model: "Perform Loan Evaluation Process")
      end
      case_i :pre_approval_declined do
          user_task("Communicate Loan Denied", groups: "credit", outputs: "Loan Denied")
      end
    end
  end


def loan_verified(data) do
  data["Loan Verified"] == "Pass"
end

def loan_failed_verification(data) do
  data["Loan Verified"] == "Fail"
end

defprocess "Perform Loan Evaluation Process" do
  case_task "Process Loan Outcome" do
    case_i :loan_verified do
      user_task("Perform Underwriting", groups: "underwriting", outputs: "Loan Approved")
      subprocess_task("Route from Underwriting", model: "Route from Underwriting Process")
    end
    case_i :loan_failed_verification do
      user_task("Communicate Loan Denied", groups: "credit", outputs: "Communicate Loan Denied")
    end
  end
end

def loan_approved(data) do
  data["Loan Approved"] == "Approved"
end

def loan_declined(data) do
  data["Loan Approved"] == "Declined"
end

def_choice_type("Communicate Loan Approved", choices: "By Phone, By US Mail")

def_choice_type("Communicate Loan Denied", choices: "By Phone, By US Mail")

defprocess "Route from Underwriting Process" do
  case_task "Route from Underwriting" do
    case_i :loan_approved do
      user_task("Communicate Approval", groups: "credit", outputs: "Communicate Loan Approved")
    end
    case_i :loan_declined do
      user_task("Communicate Loan Denied", groups: "customer_service", outputs: "Communicate Loan Denied")
    end
  end
end

end
