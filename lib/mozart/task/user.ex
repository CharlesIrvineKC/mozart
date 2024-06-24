defmodule Mozart.Task.User do
  @moduledoc """
  Used to model a task that must be completed by a system user.

  Example:

  ```
  %ProcessModel{
        name: :user_task_process_model,
        tasks: [
          %User{
            name: :user_task,
            assigned_groups: ["admin"]
          }
        ],
        initial_task: :user_task
      }
  ```

  """
  defstruct [
    :name,
    :function,
    :uid,
    :next,
    :inputs,
    :start_time,
    :finish_time,
    :duration,
    assigned_groups: [],
    complete: false,
    type: :user
  ]
end
