defmodule Mozart.Task.ReceiveEvent do
  defstruct [
    :name,
    :type,
    :function,
    :next,
    :uid,
    :message_selector,
    complete: false,
    data: %{}
  ]
end
