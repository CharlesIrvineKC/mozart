defmodule Mozart.Type.MultiChoice do
  defstruct [
    :param_name,
    :choices,
    type: :multi_choice
  ]
end
