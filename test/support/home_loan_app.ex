defmodule Mozart.HomeLoanApp do
  @moduledoc false
  use Mozart.BpmProcess

  alias Mozart.HomeLoanApp, as: ME

  def pre_approved(data) do
    data.pre_approval
  end

  def pre_approval_declined(data) do
    not data.pre_approval
  end

  defprocess "home loan process" do
    user_task("perform pre approval", groups: "credit")

    case_task("route on pre approval completion", [
      case_i &ME.pre_approved/1 do

        user_task("receive mortgage application", groups: "credit")
        user_task("process loan", groups: "credit")
        subprocess_task("perform loan evaluation", model: "perform loan evaluation process")

      end,
    case_i &ME.pre_approval_declined/1 do

        user_task("communicate loan denied", groups: "credit")
    end
    ])
  end


def loan_verified(data) do
  data.loan_verified
end

def loan_failed_verification(data) do
  ! data.loan_verified
end

defprocess "perform loan evaluation process" do
  case_task("process loan outcome", [
    case_i &ME.loan_verified/1 do

      user_task("perform underwriting", groups: "underwriting")
      subprocess_task("route from underwriting", model: "route from underwriting process")

    end,
    case_i &ME.loan_failed_verification/1 do

      user_task("communicate loan denied", groups: "credit")
    end
  ])
end

def loan_approved(data) do
  data.loan_approved
end

def loan_declined(data) do
  ! data.loan_approved
end

defprocess "route from underwriting process" do
  case_task("route from underwriting", [
    case_i &ME.loan_approved/1 do

      user_task("communicate approval", groups: "credit")
    end,
    case_i &ME.loan_declined/1 do

      user_task("communicate loan declined", groups: "customer_service")
    end
  ])
end

end
