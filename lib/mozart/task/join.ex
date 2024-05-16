defmodule Mozart.Task.Join do
  defstruct [
    :name,
    :function,
    :next,
    :uid,
    inputs: [],
    type: :join
  ]
end
