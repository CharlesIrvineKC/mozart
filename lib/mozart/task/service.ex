defmodule Mozart.Task.Service do
  @moduledoc """
  Used to model a Service task. A service task calls a function and returns
  data that is into the state data.

  Example:

  ```
  %ProcessModel{
        name: :process_with_single_service_task,
        tasks: [
          %Service{
            name: :service_task,
            input_fields: [],
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
    :function,
    :next,
    :uid,
    :input_fields,
    :start_time,
    :finish_time,
    :duration,
    type: :service
  ]
end
