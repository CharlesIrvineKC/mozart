defmodule Mozart.Task.Join do
  @moduledoc false
  defstruct [
    :name,
    :next,
    :uid,
    :start_time,
    :finish_time,
    :duration,
    :process_uid,
    inputs: [],
    type: :join
  ]
end

defimpl Mozart.Task, for: Mozart.Task.Join do
  def completable(join), do: join.inputs == []
end
