defmodule Mozart.Models.LoanApproval do
  alias Mozart.Data.ProcessModel

  alias Mozart.Task.Decision

  def get_models do
    [
      %ProcessModel{
        name: :load_approval_process,
        tasks: [
          %Decision{
            name: :loan_decision,
            decision_args: :loan_args,
            tablex:
              Tablex.new("""
              F     income      || status
              1     > 50000     || approved
              2     <= 49999    || declined
              """),
          },
        ],
        initial_task: :loan_decision
      }
    ]
  end
end
