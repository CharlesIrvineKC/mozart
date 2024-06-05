defmodule Mozart.Task.Choice do
  @moduledoc """
  Used to define a process model Choice Task. Serves the same purpose as a BPMN2 Exclusive Gate.
  The **choices** field is used to specify the multiple execution paths.

  Example:
  ```
  %ProcessModel{
        name: :choice_process_model,
        tasks: [
          %Choice{
            name: :choice_task,
            choices: [
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
        initial_task: :choice_task
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
    choices: [],
    type: :choice
  ]
end
