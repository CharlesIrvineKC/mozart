defmodule Mozart.Task.Join do
  defstruct [
    :name,
    :type,
    :function,
    :next,
    :uid,
    inputs: []
  ]
end
