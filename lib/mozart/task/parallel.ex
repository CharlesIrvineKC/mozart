defmodule Mozart.Task.Parallel do
  @moduledoc false
  defstruct [
    :name,
    :uid,
    :start_time,
    :finish_time,
    :duration,
    :process_uid,
    multi_next: [],
    type: :parallel
  ]
end

defimpl Mozart.Task, for: Mozart.Task.Parallel do
  def completable(_parallel), do: true
end
