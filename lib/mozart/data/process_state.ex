defmodule Mozart.Data.ProcessState do

  alias Mozart.Data.ProcessModel
  
  defstruct model: %ProcessModel{}, data: %{}, open_tasks: []
end
