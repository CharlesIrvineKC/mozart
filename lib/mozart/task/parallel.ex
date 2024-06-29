defmodule Mozart.Task.Parallel do
  @moduledoc false
  defstruct [
    :name,
    :uid,
    :start_time,
    :finish_time,
    :duration,
    multi_next: [],
    type: :parallel
  ]
end
