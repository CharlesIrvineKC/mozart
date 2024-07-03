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
    case_task("yes or no", [
      case_i &MyBpmApplication.x_less_than_y/1 do
        service_task("1", function: &MyBpmApplication.subtract_two_from_value/1, inputs: "value")
        service_task("2", function: &MyBpmApplication.subtract_two_from_value/1, inputs: "value")
      end,
      case_i &MyBpmApplication.x_greater_or_equal_y/1 do
        service_task("3", function: &MyBpmApplication.add_two_to_value/1, inputs: "value")
        service_task("4", function: &MyBpmApplication.add_two_to_value/1, inputs: "value")
      end
    ])
  end

  ## Send and Receive Task Example

  def receive_loan_income(msg) do
    case msg do
      {:barrower_income, income} -> %{barrower_income: income}
      _ -> nil
    end
  end

  defprocess "receive barrower income process" do
    receive_task("receive barrower income", selector: &MyBpmApplication.receive_loan_income/1)
  end

  defprocess "send barrower income process" do
    send_task("send barrower income", message: {:barrower_income, 100_000})
  end

  ## Parallel and Prototype Task Example

  defprocess "two parallel routes process" do
    parallel_task("a parallel task", [
      route do
        prototype_task("prototype task 1")
        prototype_task("prototype task 2")
      end,
      route do
        prototype_task("prototype task 3")
        prototype_task("prototype task 4")
      end
    ])
  end

  ## Repeat Task Example

  def continue(data) do
    data.continue
  end

  defprocess "repeat task process" do
    repeat_task "repeat task", &MyBpmApplication.continue/1 do
      prototype_task("prototype task 1")
      prototype_task("prototype task 2")
      user_task("user task", groups: "admin")
    end
    prototype_task("last prototype task")
  end

  ## Repeat Example with Subprocess

  defprocess "repeat with subprocess task process" do
    repeat_task "repeat task", &MyBpmApplication.continue/1 do
      subprocess_task("subprocess task", model: "subprocess with 3 prototype tasks")
      prototype_task("prototype task")
      user_task("user task", groups: "admin")
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
    repeat_task "repeat task", &MyBpmApplication.continue/1 do
      subprocess_task("subprocess task", model: "subprocess with one prototype test")
      user_task("user task", groups: "admin")
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
    repeat_task "repeat task", &MyBpmApplication.count_is_less_than_limit/1 do
      service_task("add one to count 1", function: &MyBpmApplication.add_1_to_count/1, inputs: "count")
      timer_task("timer task 1", duration: 100)
      service_task("add one to count 2", function: &MyBpmApplication.add_1_to_count/1, inputs: "count")
      timer_task("timer task 2", duration: 100)
    end
    prototype_task("last prototype task")
  end

  defprocess "subprocess with  service task" do
    service_task("add one to count", function: &MyBpmApplication.add_1_to_count/1, inputs: "count")
  end

   """
    alias Mozart.ProcessEngine, as: PE
    alias Mozart.ProcessService, as: PS
    PS.load_process_models(MyBpmApplication.get_processes())
    {:ok, ppid, uid, process_key} = PE.start_process("repeat two service tasks", %{count: 0, limit: 10})
    PE.execute(ppid)

    {:ok, ppid, uid, process_key} = PE.start_process("repeat two service tasks", %{count: 0, limit: 20})
    PE.execute(ppid)

   """


end
