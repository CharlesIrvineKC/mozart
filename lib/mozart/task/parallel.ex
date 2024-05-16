defmodule Mozart.Task.Parallel do
  defstruct [
    :name,
    :type,
    :function,
    :next,
    :uid,
    :sub_process,
    multi_next: []
  ]
end
