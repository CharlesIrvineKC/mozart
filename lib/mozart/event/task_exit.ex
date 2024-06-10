defmodule Mozart.Event.TaskExit do
  defstruct [
    :name,
    :function,
    :message_selector,
    :exit_task,
    :next,
    type: :task_exit
  ]
end
