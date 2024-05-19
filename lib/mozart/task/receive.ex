defmodule Mozart.Task.Receive do
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
