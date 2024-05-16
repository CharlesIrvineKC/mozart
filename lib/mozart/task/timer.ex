defmodule Mozart.Task.Timer do
  defstruct [
    :name,
    :type,
    :function,
    :next,
    :uid,
    :timer_duration,
    :expired
  ]
end
