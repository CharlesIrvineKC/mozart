defmodule Mozart.Data.ProcessState do

  defstruct [
    :uid,
    :parent,
    :model_name,
    task_instances: %{},
    data: %{},
    complete: false,
    children: []
  ]
end
