defmodule Mozart.Event.TaskExit do
  @moduledoc false
  defstruct [
    :name,
    :function,
    :selector,
    :exit_task,
    :next,
    type: :task_exit
  ]
end
