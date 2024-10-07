defmodule Mozart.Task.Parallel do
  @moduledoc false
  defstruct [
    :name,
    :uid,
    :start_time,
    :finish_time,
    :duration,
    :process_uid,
    multi_next: [],
    type: :parallel
  ]
end
