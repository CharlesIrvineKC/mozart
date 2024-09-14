defmodule Mozart.Task.User do
  @moduledoc false
  defstruct [
    :name,
    :listener,
    :module,
    :uid,
    :next,
    :inputs,
    :outputs,
    :start_time,
    :finish_time,
    :duration,
    :business_key,
    :process_uid,
    :assigned_user,
    :top_level_process,
    :assigned_group,
    complete: false,
    type: :user
  ]
end
