defmodule Mozart.Data.ProcessState do

  alias Mozart.Data.ProcessModel

  defstruct [
    model: %ProcessModel{},
    data: %{},
    uid: nil,
    open_tasks: nil,
    complete: false,
    parent: nil,
    children: []
  ]
end
