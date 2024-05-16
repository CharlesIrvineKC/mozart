defmodule Mozart.Task.Service do
  defstruct [
    :name,
    :function,
    :next,
    :uid,
    complete: false,
    data: %{},
    type: :service
  ]
end
