defmodule Mozart.Data.ExecutionFrame do
  @moduledoc false

  defstruct [
    :process,
    :uid,
    :parent_task_uid,
    open_tasks: %{},
    data: %{}
  ]

end
