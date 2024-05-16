defmodule Mozart.Task.Subscribe do
  defstruct [
    :name,
    :type,
    :function,
    :next,
    :uid,
    :message_selector,
    complete: false,
    data: %{}
  ]
end
