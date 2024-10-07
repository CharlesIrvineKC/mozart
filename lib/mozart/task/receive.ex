defmodule Mozart.Task.Receive do
  @moduledoc false
  defstruct [
    :name,
    :next,
    :uid,
    :selector,
    :module,
    :start_time,
    :finish_time,
    :duration,
    :process_uid,
    complete: false,
    data: %{},
    type: :receive
  ]
end
