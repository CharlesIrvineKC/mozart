defmodule Mozart.Data.ProcessState do

  defstruct [
    :uid,
    :parent,
    :model_name,
    :start_time,
    :end_time,
    :execute_duration,
    task_instances: %{},
    completed_tasks: [],
    data: %{},
    complete: false
  ]
end
