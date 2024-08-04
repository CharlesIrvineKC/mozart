defmodule Mozart.Type.Choice do
  @moduledoc false
  defstruct [
    :param_name,
    :choices,
    type: :choice,
  ]
end
