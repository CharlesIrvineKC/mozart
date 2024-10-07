defmodule Mozart.Task.Case do
  @moduledoc false

  defstruct [
    :name,
    :function,
    :next,
    :uid,
    :start_time,
    :finish_time,
    :duration,
    :process_uid,
    cases: [],
    type: :case
  ]
end

defimpl Mozart.Task, for: Mozart.Task.Case do
  def completable(_case), do: true
end
