defmodule Mozart.Task.ReceiveEvent do
  defstruct [
    :name,
    :function,
    :next,
    :uid,
    :message_selector,
    complete: false,
    data: %{},
    type: :receive_event
  ]
end
