defmodule Mozart.Task.Subprocess do
  @moduledoc false
  defstruct [
    :name,
    :next,
    :uid,
    :sub_process_model_name,
    :sub_process_pid,
    :start_time,
    :finish_time,
    :duration,
    complete: false,
    data: %{},
    type: :sub_process
  ]
end
