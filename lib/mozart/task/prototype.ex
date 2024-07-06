defmodule Mozart.Task.Prototype do
  @moduledoc false
  defstruct [
    :name,
    :next,
    :uid,
    :start_time,
    :finish_time,
    :duration,
    :process_uid,
    type: :prototype
  ]
end
