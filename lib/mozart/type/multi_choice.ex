defmodule Mozart.Type.MultiChoice do
  @moduledoc false
  defstruct [
    :param_name,
    :choices,
    type: :multi_choice
  ]
end
