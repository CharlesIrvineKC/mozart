defmodule Mozart.Task.Service do
  @moduledoc false
  defstruct [
    :name,
    :function,
    :inputs,
    :next,
    :uid,
    :start_time,
    :finish_time,
    :duration,
    type: :service
  ]
end
