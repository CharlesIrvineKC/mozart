defmodule Mozart.Task.User do
  defstruct [
    :name,
    :type,
    :function,
    :next,
    :uid,
    assigned_groups: [],
    complete: false
  ]
end
