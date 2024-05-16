defmodule Mozart.Task.Choice do
  defstruct [
    :name,
    :type,
    :function,
    :next,
    :uid,
    choices: []
  ]
end
