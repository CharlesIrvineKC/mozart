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

  ## Subprocess Task Example

  def add_one_to_value(data) do
    Map.put(data, :value, data.value + 1)
  end

  defprocess "two service tasks" do
    service_task("service task 2", function: &MyBpmApplication.add_one_to_value/1, inputs: "value")
    service_task("service task 3", function: &MyBpmApplication.add_one_to_value/1, inputs: "value")
  end

  defprocess "subprocess task process" do
    service_task("service task 2", function: &MyBpmApplication.add_one_to_value/1, inputs: "value")
    subprocess_task("subprocess task", model: "two service tasks")
  end

end
