defmodule Mozart.LoanApprovalTest do
  use ExUnit.Case

  alias Mozart.ProcessService, as: PS
  alias Mozart.ProcessEngine, as: PE
  alias HomeLoanApp

test "run loan approval" do
  PS.clear_state()
  PS.load_process_models(HomeLoanApp.get_processes())
  data = %{credit_score: 700, income: 100_000, debt_amount: 20_000}
  {:ok, ppid, uid, _process_key} = PE.start_process("home loan process", data)
  PE.execute(ppid)
  Process.sleep(100)

  ## complete pre approval
  [user_task] = PS.get_user_tasks_for_groups(["credit"])
  PS.complete_user_task(user_task.uid, %{pre_approval: true})
  Process.sleep(100)

  ## complete receive mortgage application
  [user_task] = PS.get_user_tasks_for_groups(["credit"])
  PS.complete_user_task(user_task.uid, %{purchase_price: 500_000})
  Process.sleep(100)

  ## process loan
  [user_task] = PS.get_user_tasks_for_groups(["credit"])
  PS.complete_user_task(user_task.uid, %{loan_verified: true})
  Process.sleep(100)

  ## perform underwriting
  [user_task] = PS.get_user_tasks_for_groups(["underwriting"])
  PS.complete_user_task(user_task.uid, %{loan_approved: true})
  Process.sleep(100)

  ## communicate approval
  [user_task] = PS.get_user_tasks_for_groups(["underwriting"])
  PS.complete_user_task(user_task.uid, %{loan_approved: true})
  Process.sleep(100)

  completed_process = PS.get_completed_process(uid)
  completed_tasks = completed_process.completed_tasks
  assert Enum.all?(completed_tasks, fn t -> t.duration end) == true
end

end
