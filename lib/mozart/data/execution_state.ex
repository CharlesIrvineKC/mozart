defmodule Mozart.Data.ExecutionState do
  @moduledoc false

  defstruct [
    :process,
    :uid,
    :parent_task_uid,
    open_tasks: %{},
    data: %{}
  ]

end
