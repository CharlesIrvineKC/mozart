defmodule Mozart.Task.Reroute do
  @moduledoc false
  defstruct [
    :name,
    :condition,
    :module,
    :next,
    :reroute_first,
    :uid,
    :start_time,
    :finish_time,
    :duration,
    :process_uid,
    type: :reroute
  ]
end

defimpl Mozart.Task, for: Mozart.Task.Reroute do
  def completable(_reroute), do: true
end
