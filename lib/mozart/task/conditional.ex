defmodule Mozart.Task.Conditional do
  @moduledoc false
  defstruct [
    :name,
    :next,
    :uid,
    :model,
    :condition,
    :module,
    :first,
    :last,
    :start_time,
    :finish_time,
    :duration,
    :process_uid,
    complete: false,
    type: :conditional
  ]
end
