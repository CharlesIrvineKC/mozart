defmodule Mozart.Data.ProcessModel do
  @moduledoc false
  defstruct [:name, :initial_task, tasks: [], events: []]
end
