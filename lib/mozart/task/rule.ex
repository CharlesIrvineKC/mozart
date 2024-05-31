defmodule Mozart.Task.Rule do
  @moduledoc """
  Used to model a Mozart run task. Called a Business Rule in BPMN2. Uses
  the Elixir [tablex](https://hex.pm/packages/tablex) library.

  Example:

  ```
  %ProcessModel{
        name: :load_approval,
        tasks: [
          %Decision{
            name: :loan_decision,
            decision_args: :loan_args,
            tablex:
              Tablex.new(\"""
              F     income      || status
              1     > 50000     || approved
              2     <= 49999    || declined
              \"""),
          },
        ],
        initial_task: :loan_decision
      }
  ```
  """

  defstruct [
    :name,
    :next,
    :uid,
    :tablex,
    :decision_args,
    type: :rule
  ]
end
