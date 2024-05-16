defmodule Mozart.Task.Choice do
  defstruct [
    :name,
    :function,
    :next,
    :uid,
    choices: [],
    type: :choice
  ]
end
