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
    :process_uid,
    type: :service
  ]
end
