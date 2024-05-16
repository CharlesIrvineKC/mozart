defmodule Mozart.Task.SendEvent do
  defstruct [
    :name,
    :next,
    :uid,
    :message,
    type: :send_event
  ]
end
