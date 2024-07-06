defmodule Mozart.Task.Subprocess do
  @moduledoc false
  defstruct [
    :name,
    :next,
    :uid,
    :model,
    :subprocess_pid,
    :start_time,
    :finish_time,
    :duration,
    :process_uid,
    complete: false,
    data: %{},
    type: :subprocess
  ]
end
