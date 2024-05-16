defmodule Mozart.Task.Subprocess do
  defstruct [
    :name,
    :function,
    :next,
    :uid,
    :sub_process,
    complete: false,
    data: %{},
    type: :sub_process
  ]
end
