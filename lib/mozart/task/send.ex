defmodule Mozart.Task.Send do
  @moduledoc false
  defstruct [
    :name,
    :next,
    :uid,
    :message,
    :generator,
    :module,
    :start_time,
    :finish_time,
    :duration,
    :process_uid,
    type: :send
  ]
end
