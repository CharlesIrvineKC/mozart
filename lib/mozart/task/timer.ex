defmodule Mozart.Task.Timer do
  @moduledoc """
  Used to model a task waits a specified duration and automatically completes.

  Example:

  ```
  %ProcessModel{
      name: :call_timer_task,
      tasks: [
        %Timer{
          name: :wait_1_seconds,
          timer_duration: 10
        },
      ],
      initial_task: :wait_1_seconds
    }
  ```

  """
  defstruct [
    :name,
    :function,
    :next,
    :uid,
    :timer_duration,
    :expired,
    :start_time,
    :finish_time,
    :duration,
    type: :timer
  ]
end
