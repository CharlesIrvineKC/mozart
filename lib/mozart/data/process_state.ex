defmodule Mozart.Data.ProcessState do

  alias Mozart.Data.ProcessModel

  defstruct [
    model: %ProcessModel{},
    data: %{},
    uid: nil,
    task_instances: nil,
    complete: false,
    parent: nil,
    children: []
  ]
end
