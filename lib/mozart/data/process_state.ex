defmodule Mozart.Data.ProcessState do
@moduledoc false

  defstruct [
    :uid,
    :business_key,
    :start_time,
    :end_time,
    :execute_duration,
    data: %{},
    execution_states: [],
    completed_tasks: [],
    complete: false
  ]
end
