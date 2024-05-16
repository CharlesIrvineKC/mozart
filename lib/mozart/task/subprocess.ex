defmodule Mozart.Task.Subprocess do
  defstruct [
    :name,
    :type,
    :function,
    :next,
    :uid,
    :sub_process,
    complete: false,
    data: %{}
  ]
end
