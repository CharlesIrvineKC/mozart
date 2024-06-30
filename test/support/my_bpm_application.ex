defmodule MyBpmApplication do
  @moduledoc false
  use Mozart.BpmProcess

  ## Service Task Example

  def sum(data) do
    %{sum: data.x + data.y}
  end

  defprocess "add x and y process" do
    service_task("add x and y task", function: &MyBpmApplication.sum/1, inputs: "x,y")
  end

  ## User Task Example

  defprocess "one user task process" do
    user_task("user gives sum of x and y", groups: "admin", inputs: "x,y")
  end

end
