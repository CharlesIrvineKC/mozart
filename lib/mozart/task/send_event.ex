defmodule Mozart.Task.SendEvent do
  defstruct [
    :name,
    :function,
    :next,
    :uid,
    type: :send_event,
    data: %{}
  ]
end
