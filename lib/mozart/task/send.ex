defmodule Mozart.Task.Send do
  @moduledoc false
  defstruct [
    :name,
    :next,
    :uid,
    :message,
    :start_time,
    :finish_time,
    :duration,
    type: :send
  ]
end
