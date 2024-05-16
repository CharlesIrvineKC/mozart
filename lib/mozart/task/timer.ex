defmodule Mozart.Task.Timer do
  defstruct [
    :name,
    :function,
    :next,
    :uid,
    :timer_duration,
    :expired,
    type: :timer
  ]
end
