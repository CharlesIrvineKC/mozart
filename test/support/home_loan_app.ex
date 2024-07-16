defmodule HomeLoanApp do
  @moduledoc false
  use Mozart.BpmProcess

  def pre_approved(data) do
    data.pre_approval
  end

  def pre_approval_declined(data) do
    not data.pre_approval
  end

  defprocess "home loan process" do
    user_task("perform pre approval", groups: "credit")

    case_task "route on pre approval completion" do
      case_i :pre_approved do

        user_task("receive mortgage application", groups: "credit")
        user_task("process loan", groups: "credit")
        subprocess_task("perform loan evaluation", model: "perform loan evaluation process")

      end
      case_i :pre_approval_declined do

          user_task("communicate loan denied", groups: "credit")
      end
    end
  end


def loan_verified(data) do
  data.loan_verified
end

def loan_failed_verification(data) do
  ! data.loan_verified
end

defprocess "perform loan evaluation process" do
  case_task "process loan outcome" do
    case_i :loan_verified do

      user_task("perform underwriting", groups: "underwriting")
      subprocess_task("route from underwriting", model: "route from underwriting process")

    end
    case_i :loan_failed_verification do

      user_task("communicate loan denied", groups: "credit")
    end
  end
end

def loan_approved(data) do
  data.loan_approved
end

def loan_declined(data) do
  ! data.loan_approved
end

defprocess "route from underwriting process" do
  case_task "route from underwriting" do
    case_i :loan_approved do

      user_task("communicate approval", groups: "credit")
    end
    case_i :loan_declined do

      user_task("communicate loan declined", groups: "customer_service")
    end
  end
end

end
