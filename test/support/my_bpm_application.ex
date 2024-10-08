defmodule MyBpmApplication do
  @moduledoc false
  use Mozart.BpmProcess

  ## Service Task Example

  def sum(data) do
    %{sum: data.x + data.y}
  end

  defprocess "add x and y process" do
    service_task("add x and y task", function: {:sum, 1}, inputs: "x,y")
  end

  ## User Task Example

  defprocess "one user task process" do
    user_task("user gives sum of x and y", group: "admin", inputs: "x,y", outputs: "na")
  end

  ## Subprocess Task Example

  def add_one_to_value(data) do
    Map.put(data, :value, data.value + 1)
  end

  defprocess "two service tasks" do
    service_task("service task 2", function: :add_one_to_value, inputs: "value")
    service_task("service task 3", function: :add_one_to_value, inputs: "value")
  end

  defprocess "subprocess task process" do
    service_task("service task 2", function: :add_one_to_value, inputs: "value")
    subprocess_task("subprocess task", process: "two service tasks")
  end

  ## Case Task Example

  def add_two_to_value(data) do
    Map.put(data, :value, data.value + 2)
  end

  def subtract_two_from_value(data) do
    Map.put(data, :value, data.value - 2)
  end

  def x_less_than_y(data) do
    data.x < data.y
  end

  def x_greater_or_equal_y(data) do
    data.x >= data.y
  end

  defprocess "two case process" do
    case_task "yes or no" do
      case_i &MyBpmApplication.x_less_than_y/1 do
        service_task("1", function: :subtract_two_from_value, inputs: "value")
        service_task("2", function: :subtract_two_from_value, inputs: "value")
      end
      case_i &MyBpmApplication.x_greater_or_equal_y/1 do
        service_task("3", function: :add_two_to_value, inputs: "value")
        service_task("4", function: :add_two_to_value, inputs: "value")
      end
    end
  end

  ## Send and Receive Task Example

  def receive_loan_income(msg) do
    case msg do
      {:barrower_income, income} -> %{barrower_income: income}
      _ -> nil
    end
  end

  defprocess "receive barrower income process" do
    receive_task("receive barrower income", selector: :receive_loan_income)
  end

  defprocess "send barrower income process" do
    send_task("send barrower income", message: {:barrower_income, 100_000})
  end

  ## Parallel and Prototype Task Example

  defprocess "two parallel routes process" do
    parallel_task "a parallel task" do
      route do
        prototype_task("prototype task 1")
        prototype_task("prototype task 2")
      end
      route do
        prototype_task("prototype task 3")
        prototype_task("prototype task 4")
      end
    end
  end

  ## Repeat Task Example

  def continue(data) do
    data.continue
  end

  defprocess "repeat task process" do
    repeat_task "repeat task", condition: :continue do
      prototype_task("prototype task 1")
      prototype_task("prototype task 2")
      user_task("user task", group: "admin", outputs: "na")
    end
    prototype_task("last prototype task")
  end

  ## Repeat Example with Subprocess

  defprocess "repeat with subprocess task process" do
    repeat_task "repeat task", condition: :continue do
      subprocess_task("subprocess task", process: "subprocess with 3 prototype tasks")
      prototype_task("prototype task")
      user_task("user task", group: "admin", outputs: "na")
    end
    prototype_task("last prototype task")
  end

  defprocess "subprocess with 3 prototype tasks" do
    prototype_task("subprocess prototype task 1")
    prototype_task("subprocess prototype task 2")
    prototype_task("subprocess prototype task 3")
  end

  ## From Tests

  defprocess "repeat with subprocess task process 2" do
    repeat_task "repeat task", condition: :continue do
      subprocess_task("subprocess task", process: "subprocess with one prototype test")
      user_task("user task", group: "admin", outputs: "na")
    end
    prototype_task("last prototype task")
  end

  defprocess "subprocess with one prototype test" do
    prototype_task("subprocess prototype task 1")
  end

  ## Repeat with service tasks and subprocess

  def count_is_less_than_limit(data) do
    data.count < data.limit
  end

  def add_1_to_count(data) do
    %{count: data.count + 1}
  end

  defprocess "repeat two service tasks" do
    repeat_task "repeat task", condition: :count_is_less_than_limit do
      service_task("add one to count 1", function: :add_1_to_count, inputs: "count")
      timer_task("timer task 1", duration: 100)
      service_task("add one to count 2", function: :add_1_to_count, inputs: "count")
      timer_task("timer task 2", duration: 100)
    end
    prototype_task("last prototype task")
  end

  defprocess "subprocess with  service task" do
    service_task("add one to count", function: :add_1_to_count, inputs: "count")
  end

  ## Rule Task Example

  rule_table = """
  F     income      || status
  1     > 50000     || approved
  2     <= 49999    || declined
  """

  defprocess "single rule task process" do
    rule_task("loan decision", inputs: "income", rule_table: rule_table)
  end

  ## Task Exit Event Example

  def exit_subprocess_task_event_selector(message) do
    case message do
      :exit_subprocess_task -> true
      _ -> nil
    end
  end

  defprocess "exit a subprocess task" do
    subprocess_task("subprocess task", process: "subprocess process")
  end

  defprocess "subprocess process" do
    user_task("user task", group: "admin", outputs: "na")
  end

  def_task_exit_event "exit subprocess task",
    process: "exit a subprocess task",
    exit_task: "subprocess task",
    selector: &MyBpmApplication.exit_subprocess_task_event_selector/1 do
      prototype_task("prototype task 1")
      prototype_task("prototype task 2")
  end

end
