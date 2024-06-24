defmodule Mozart.Task.Service do
  @moduledoc """
  Used to model a Service task. A service task calls a function and returns
  data that is into the state data.

  Example:

  ```
  %ProcessModel{
        name: :process_with_single_service_task,
        tasks: [
          %Script{
            name: :service_task,
            inputs: [],
            function: fn data -> Map.merge(data, %{single_service: true}) end
          }
        ],
        initial_task: :service_task
      }
  ```

  """

  @doc ""
  defstruct [
    :name,
    :module,
    :function,
    :inputs,
    :next,
    :uid,
    :start_time,
    :finish_time,
    :duration,
    type: :service
  ]
end
