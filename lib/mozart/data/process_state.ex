defmodule Mozart.Data.ProcessState do

  alias Mozart.Data.ProcessModel

  defstruct model: %ProcessModel{}, data: %{}, id: nil, open_task_names: nil
end
