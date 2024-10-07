defmodule Mozart.Task.Send do
  @moduledoc false
  defstruct [
    :name,
    :next,
    :uid,
    :message,
    :start_time,
    :finish_time,
    :duration,
    :process_uid,
    type: :send
  ]
end

defimpl Mozart.Task, for: Mozart.Task.Send do
  def completable(_send), do: true
end
