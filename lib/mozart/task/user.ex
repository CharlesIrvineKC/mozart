defmodule Mozart.Task.User do
  @moduledoc false
  defstruct [
    :name,
    :function,
    :uid,
    :next,
    :inputs,
    :start_time,
    :finish_time,
    :duration,
    :process_uid,
    assigned_groups: [],
    complete: false,
    type: :user
  ]
end
