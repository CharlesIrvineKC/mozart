defmodule Mozart.Data.ProcessState do

  alias Mozart.Data.ProcessModel

  defstruct [
    :uid,
    :parent,
    :task_instances,
    model: %ProcessModel{},
    data: %{},
    complete: false,
    children: []
  ]
end
