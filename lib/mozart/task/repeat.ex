defmodule Mozart.Task.Repeat do
  @moduledoc false
  defstruct [
    :name,
    :next,
    :first,
    :last,
    :complete,
    :uid,
    :condition,
    :module,
    :start_time,
    :finish_time,
    :duration,
    :process_uid,
    inputs: [],
    type: :repeat
  ]
end
