defmodule Mozart.Type.MultiChoice do
  defstruct [
    :param_name,
    :choices,
    type: :multiple_choice
  ]
end
