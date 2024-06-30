defmodule Mozart.Task.Prototype do
  @moduledoc false
  defstruct [
    :name,
    :next,
    :uid,
    :start_time,
    :finish_time,
    :duration,
    type: :prototype
  ]
end
