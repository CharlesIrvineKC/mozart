defmodule Mozart.Type.Number do
  @moduledoc false
  defstruct [
    :param_name,
    :max,
    :min,
    type: :number
  ]
end
