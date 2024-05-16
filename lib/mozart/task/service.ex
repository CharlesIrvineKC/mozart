defmodule Mozart.Task.Service do
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
