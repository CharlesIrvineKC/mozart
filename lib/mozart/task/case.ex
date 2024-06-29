defmodule Mozart.Task.Case do
  @moduledoc false
  defstruct [
    :name,
    :function,
    :next,
    :uid,
    :start_time,
    :finish_time,
    :duration,
    cases: [],
    type: :case
  ]
end
