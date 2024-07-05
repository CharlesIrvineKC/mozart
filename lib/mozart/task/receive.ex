defmodule Mozart.Task.Receive do
  @moduledoc false
  defstruct [
    :name,
    :function,
    :next,
    :uid,
    :selector,
    :start_time,
    :finish_time,
    :duration,
    complete: false,
    data: %{},
    type: :receive
  ]
end
