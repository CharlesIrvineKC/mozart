defmodule Mozart.Task.Case do
  @moduledoc """
  Used to define a process model Case Task. Serves the same purpose as a BPMN2 Exclusive Gate.
  The **cases** field is used to specify the multiple execution paths.

  Example:
  ```
  %ProcessModel{
        name: :case_process_model,
        tasks: [
          %Case{
            name: :case_task,
            cases: [
              %{
                expression: fn data -> data.value < 10 end,
                next: :foo
              },
              %{
                expression: fn data -> data.value >= 10 end,
                next: :bar
              }
            ]
          }
        ],
        initial_task: :case_task
      }
  ```

  """
  defstruct [
    :name,
    :function,
    :next,
    :uid,
    :start_time,
    :finish_time,
    :duration,
    cases: [],
    type: :case
  ]
end
