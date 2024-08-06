defmodule Mozart.Task.Exception do
  @moduledoc false
  defstruct [
    :name,
    :condition,
    :next,
    :exception_first,
    :uid,
    :start_time,
    :finish_time,
    :duration,
    :process_uid,
    type: :exception
  ]
end
