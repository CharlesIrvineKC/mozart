defmodule Mozart.Task.Case do
  @moduledoc false
  defstruct [
    :name,
    :next,
    :uid,
    :start_time,
    :finish_time,
    :duration,
    :process_uid,
    cases: [],
    type: :case
  ]
end
