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
    :process_uid,
    type: :rule
  ]
end
