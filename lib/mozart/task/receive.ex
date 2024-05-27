defmodule Mozart.Task.Receive do
  @moduledoc """
  Used to model a task that waits for a PubSub message. Functional but needs
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
    :function,
    :next,
    :uid,
    :message_selector,
    complete: false,
    data: %{},
    type: :receive
  ]
end
