defmodule Mozart.Task.Timer do
  @moduledoc false
  defstruct [
    :name,
    :next,
    :uid,
    :timer_duration,
    :function,
    :module,
    :expired,
    :start_time,
    :finish_time,
    :duration,
    :process_uid,
    type: :timer
  ]
end
