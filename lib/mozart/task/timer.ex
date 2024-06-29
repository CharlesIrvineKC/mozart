defmodule Mozart.Task.Timer do
  @moduledoc false
  defstruct [
    :name,
    :function,
    :next,
    :uid,
    :timer_duration,
    :expired,
    :start_time,
    :finish_time,
    :duration,
    type: :timer
  ]
end
