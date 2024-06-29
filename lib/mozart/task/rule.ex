defmodule Mozart.Task.Rule do
  @moduledoc false

  defstruct [
    :name,
    :next,
    :uid,
    :rule_table,
    :inputs,
    :start_time,
    :finish_time,
    :duration,
    type: :rule
  ]
end
