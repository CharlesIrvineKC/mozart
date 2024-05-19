defmodule Mozart.Task.Send do
  defstruct [
    :name,
    :next,
    :uid,
    :message,
    type: :send
  ]
end
