defmodule Mozart.Data.ProcessState do

  alias Mozart.Data.ProcessModel

  defstruct [
    model: %ProcessModel{},
    data: %{},
    uid: nil,
    task_instances: nil,
    pending_sub_tasks: [],
    complete: false,
    parent: nil,
    children: []
  ]
end
