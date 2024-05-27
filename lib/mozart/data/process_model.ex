defmodule Mozart.Data.ProcessModel do
  @moduledoc """
  This struct is used to create business process models. Also see Mozart.Task modules.

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
  defstruct [:name, :tasks, :initial_task]
end
