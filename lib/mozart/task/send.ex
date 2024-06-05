defmodule Mozart.Task.Send do
  @moduledoc """
  Used to send a PubSub message to a waiting Receive task. Functioal but needs
  some work.

  Example:

  ```
  %ProcessModel{
        name: :process_with_receive_task,
        tasks: [
          %Receive{
            name: :receive_task,
            message_selector: fn msg ->
              case msg do
                :message -> %{message: true}
                _ -> false
              end
            end
          }
        ],
        initial_task: :receive_task
      },
      %ProcessModel{
        name: :process_with_single_send_task,
        tasks: [
          %Send{
            name: :send_task,
            message: :message
          },
        ],
        initial_task: :send_task
      }
  ```

  """
  defstruct [
    :name,
    :next,
    :uid,
    :message,
    :start_time,
    :finish_time,
    :duration,
    type: :send
  ]
end
