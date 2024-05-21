
defmodule Mozart.Task.Decision do
  defstruct [
    :name,
    :next,
    :uid,
    :tablex,
    :decision_args,
    type: :decision
  ]
end
