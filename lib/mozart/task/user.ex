defmodule Mozart.Task.User do
  @moduledoc false
  defstruct [
    :name,
    :data,
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
    :assigned_group,
    :top_level_process,
    complete: false,
    type: :user
  ]
end
