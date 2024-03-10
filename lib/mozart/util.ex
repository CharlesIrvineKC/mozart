defmodule Mozart.Util do

  alias Mozart.Data.ProcessModel
  alias Mozart.Data.ProcessState

  def get_simple_state() do
    %ProcessState{
      model: %ProcessModel{name: "foo", tasks: [], initial_task: :foo}
    }
  end
end
