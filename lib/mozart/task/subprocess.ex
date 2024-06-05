defmodule Mozart.Task.Subprocess do
  @moduledoc """
  Used to model a task that is completed by executing and completing a
  subprocess. Called a **call activity** in BPMN2.

  Example:

  ```
  %ProcessModel{
        name: :call_process_model,
        tasks: [
          %Subprocess{
            name: :call_process_task,
            sub_process: :service_subprocess_model,
            next: :service_task1
          },
          %Service{
            name: :service_task1,
            function: fn data -> Map.put(data, :value, data.value + 1) end
          }
        ],
        initial_task: :call_process_task
      },
      %ProcessModel{
        name: :service_subprocess_model,
        tasks: [
          %Service{
            name: :service_task,
            function: fn data -> Map.put(data, :subprocess_data, "subprocess data") end
          }
        ],
        initial_task: :service_task
      }
  ```
  """
  defstruct [
    :name,
    :next,
    :uid,
    :sub_process,
    :start_time,
    :finish_time,
    :duration,
    complete: false,
    data: %{},
    type: :sub_process
  ]
end
