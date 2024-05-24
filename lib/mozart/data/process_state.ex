defmodule Mozart.Data.ProcessState do

  defstruct [
    :uid,
    :parent,
    :model_name,
    task_instances: %{},
    completed_tasks: [],
    data: %{},
    complete: false
  ]
end
