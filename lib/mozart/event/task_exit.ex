defmodule Mozart.Event.TaskExit do
  @moduledoc false
  defstruct [
    :name,
    :selector,
    :module,
    :exit_task,
    :next,
    type: :task_exit
  ]
end
