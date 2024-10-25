defmodule Mozart.Data.ProcessState do
@moduledoc false

  defstruct [
    :uid,
    :business_key,
    :start_time,
    :end_time,
    :top_level_process,
    :execute_duration,
    notes: %{},
    data: %{},
    execution_frames: [],
    completed_tasks: [],
    complete: false
  ]
end
