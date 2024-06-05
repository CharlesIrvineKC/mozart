defmodule Mozart.Task.Rule do
  @moduledoc """
  Used to model a Mozart run task. Called a Business Rule in BPMN2. Uses
  the Elixir [rule_table](https://hex.pm/packages/rule_table) library.

  Example:

  ```
  %ProcessModel{
        name: :load_approval,
        tasks: [
          %Decision{
            name: :loan_decision,
            input_fields: [:income],
            rule_table:
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
    :rule_table,
    :input_fields,
    :start_time,
    :finish_time,
    :duration,
    type: :rule
  ]
end
