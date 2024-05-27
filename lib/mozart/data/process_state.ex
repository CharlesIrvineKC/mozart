defmodule Mozart.Data.ProcessState do

  defstruct [
    :uid,
    :parent,
    :model_name,
    :start_time,
    :end_time,
    :execute_duration,
    open_tasks: %{},
    completed_tasks: [],
    data: %{},
    complete: false
  ]
end
