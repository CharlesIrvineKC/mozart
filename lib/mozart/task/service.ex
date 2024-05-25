defmodule Mozart.Task.Service do
  defstruct [
    :name,
    :function,
    :next,
    :uid,
    data: %{},
    type: :service
  ]
end
