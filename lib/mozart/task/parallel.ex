defmodule Mozart.Task.Parallel do
  defstruct [
    :name,
    :function,
    :next,
    :uid,
    :sub_process,
    multi_next: [],
    type: :parallel
  ]
end
