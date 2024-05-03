defmodule Mozart.Data.ProcessState do

  defstruct [
    :uid,
    :parent,
    :task_instances,
    :model_name,
    data: %{},
    complete: false,
    children: []
  ]
end
