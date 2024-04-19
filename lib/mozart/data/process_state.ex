defmodule Mozart.Data.ProcessState do

  alias Mozart.Data.ProcessModel

  defstruct [
    model: %ProcessModel{},
    data: %{},
    uid: nil,
    open_task_names: nil,
    complete: false,
    parent: nil
  ]
end
