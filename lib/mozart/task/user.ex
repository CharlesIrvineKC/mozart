defmodule Mozart.Task.User do
  defstruct [
    :name,
    :function,
    :uid,
    next: nil,
    assigned_groups: [],
    complete: false,
    type: :user
  ]
end
