defmodule Mozart.Task.Join do
  @moduledoc false
  defstruct [
    :name,
    :next,
    :uid,
    :start_time,
    :finish_time,
    :duration,
    :process_uid,
    inputs: [],
    type: :join
  ]
end
