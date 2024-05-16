defmodule Mozart.Task.Task do
  defstruct [
    :name,
    :type,
    :function,
    :next,
    :uid,
    :process_uid,
    :sub_process,
    :assignee,
    :timer_duration,
    :message_selector,
    expired: false,
    event_received: false,
    multi_next: [],
    inputs: [],
    choices: [],
    assigned_groups: [],
    complete: false,
    data: %{}
  ]
end
