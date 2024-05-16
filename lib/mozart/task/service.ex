defmodule Mozart.Task.Service do
  defstruct [
    :name,
    :type,
    :function,
    :next,
    :uid,
    complete: false,
    data: %{}
  ]
end