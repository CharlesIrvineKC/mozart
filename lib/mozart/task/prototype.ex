defmodule Mozart.Task.Prototype do
  @moduledoc false
  defstruct [
    :name,
    :data,
    :next,
    :uid,
    :start_time,
    :finish_time,
    :duration,
    :process_uid,
    type: :prototype
  ]
end

defimpl Mozart.Task, for: Mozart.Task.Prototype do
  def completable(_prototype), do: true
end
