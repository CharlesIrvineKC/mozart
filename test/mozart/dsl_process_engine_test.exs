defmodule Mozart.DslProcessEngineTest do
  use ExUnit.Case
  use Mozart.BpmProcess

  alias Phoenix.PubSub
  alias Mozart.ProcessEngine, as: PE
  alias Mozart.ProcessService, as: PS

  alias Mozart.Type.Number
  alias Mozart.Type.Choice
  alias Mozart.Type.MultiChoice
  alias Mozart.Type.Confirm

  def do_conditional_tasks(_data) do
    true
  end

  defprocess "process with conditional task" do
    prototype_task("initial task")
    conditional_task "a conditional task", condition: :do_conditional_tasks do
      prototype_task("first prototype task")
      prototype_task("last prototype task")
    end
    prototype_task("final prototype task")
  end

  test "process with conditional task" do
    PS.clear_state()
    load()
    data = %{}

    {:ok, ppid, uid, _business_key} = PE.start_process("process with conditional task", data)
    PE.execute(ppid)
    Process.sleep(200)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 5
  end

  defprocess "prototype task with data" do
    prototype_task("a prototype task", %{foo: :foo})
  end

  test "prototype task with data" do
    PS.clear_state()
    load()
    data = %{}

    {:ok, ppid, uid, _business_key} = PE.start_process("prototype task with data", data)
    PE.execute(ppid)
    Process.sleep(100)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{foo: :foo}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 1
  end

  defprocess "parallel prototype tasks" do
    parallel_task "a parallel task" do
      route do
        prototype_task("prototype task route one")
      end
      route do
        prototype_task("prototype task route two")
      end
    end
  end

  test "parallel prototype tasks" do
    PS.clear_state()
    load()
    data = %{}

    {:ok, ppid, uid, _business_key} = PE.start_process( "parallel prototype tasks", data)
    PE.execute(ppid)
    Process.sleep(100)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 3
  end

  def fail_1(_data) do
    false
  end

  def fail_2(_data) do
    true
  end

  defprocess "multi branching process" do
    prototype_task("1")
    reroute_task "fail 1", condition: :fail_1 do
      prototype_task("1.1")
      prototype_task("1.1.2")
    end
    prototype_task("1.2")
    reroute_task "fail 2", condition: :fail_2 do
      prototype_task("1.2.2")
    end
    prototype_task("1.2.1")
  end

  test "multi branching process" do
    PS.clear_state()
    load()
    data = %{}

    {:ok, ppid, uid, _business_key} = PE.start_process("multi branching process", data)
    PE.execute(ppid)
    Process.sleep(100)

    completed_process =PS.get_completed_process(uid)
    assert completed_process.data == %{}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 5
  end

  def test(_data) do
    false
  end

  defprocess "reroute task and prototype task" do
    reroute_task "reroute task", condition: :test do
      prototype_task("reroute prototype task 1")
      prototype_task("reroute prototype task 2")
    end
    prototype_task("Finish Up Task 1")
    prototype_task("Finish Up Task 2")
  end

  test "reroute task and prototype task" do
    PS.clear_state()
    load()
    data = %{}

    {:ok, ppid, uid, _business_key} = PE.start_process("reroute task and prototype task", data)
    PE.execute(ppid)
    Process.sleep(100)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 3
  end

  def_number_type("number param", min: 0, max: 5)
  def_choice_type("choice param", choices: "foo, bar")
  def_multi_choice_type("multi choice param", choices: "foo,bar,foobar")
  def_confirm_type("confirm param")

  test "params type generation" do
    PS.clear_state()
    load()
    Process.sleep(100)

    assert PS.get_type("number param") ==
      %Number{param_name: "number param", max: 5, min: 0, type: :number}

    assert PS.get_type("choice param") ==
      %Choice{param_name: "choice param", choices: ["foo", "bar"], type: :choice}

    assert PS.get_type("multi choice param") ==
      %MultiChoice{
        param_name: "multi choice param",
        choices: ["foo", "bar", "foobar"],
        type: :multi_choice}

      assert PS.get_type("confirm param") == %Confirm{param_name: "confirm param", type: :confirm}
  end

  defprocess "one prototype task process" do
    prototype_task("a prototype task")
  end

  test "test bpm application test" do
  end

  defprocess "one user task process" do
    user_task("add one to x 1", groups: "admin", outputs: "x")
  end

  test "multiple processes of on user task" do
    PS.clear_state()
    load()
    data = %{}

    {:ok, ppid_1, _uid, _business_key} = PE.start_process("one user task process", data)
    PE.execute(ppid_1)
    {:ok, ppid_2, _uid, _business_key} = PE.start_process("one user task process", data)
    PE.execute(ppid_2)
    {:ok, ppid_3, _uid, _business_key} = PE.start_process("one user task process", data)
    PE.execute(ppid_3)
    Process.sleep(100)

    assert length(PS.get_user_tasks()) == 3
  end

  def exit_subprocess_task_event_selector(message) do
    case message do
      :exit_subprocess_task -> true
      _ -> nil
    end
  end

  defprocess "exit a subprocess task" do
    subprocess_task("subprocess task", model: "subprocess process")
  end

  defprocess "subprocess process" do
    user_task("user task", groups: "admin", outputs: "na")
  end

  defevent "exit subprocess task",
    process: "exit a subprocess task",
    exit_task: "subprocess task",
    selector: :exit_subprocess_task_event_selector do
      prototype_task("prototype task 1")
      prototype_task("prototype task 2")
  end

  test  "exit a subprocess task" do
    PS.clear_state()
    load()
    data = %{}

    {:ok, ppid, uid, _business_key} = PE.start_process( "exit a subprocess task", data)
    PE.execute(ppid)
    Process.sleep(100)

    PubSub.broadcast(:pubsub, "pe_topic", {:event, :exit_subprocess_task})
    Process.sleep(100)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 3
  end

  def exit_user_task_event_selector(message) do
    case message do
      :exit_user_task -> true
      _ -> nil
    end
  end

  defprocess "exit a user task" do
    user_task("user task", groups: "admin", outputs: "na")
  end

  defevent "exit loan decision",
    process: "exit a user task",
    exit_task: "user task",
    selector: :exit_user_task_event_selector do
      prototype_task("prototype task 1")
      prototype_task("prototype task 2")
  end

  test  "exit a user task 1" do
    PS.clear_state()
    load()
    data = %{}

    {:ok, ppid, uid, _business_key} = PE.start_process( "exit a user task", data)
    PE.execute(ppid)
    Process.sleep(100)

    PubSub.broadcast(:pubsub, "pe_topic", {:event, :exit_user_task})
    Process.sleep(100)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 3
  end

  def count_is_less_than_limit(data) do
    data["count"] < data["limit"]
  end

  def add_1_to_count(data) do
    %{"count" => data["count"] + 1}
  end

  defprocess "repeat with service task process" do
    repeat_task "repeat task", condition: :count_is_less_than_limit do
      service_task("add one to count 1", function: :add_1_to_count, inputs: "count")
    end
    prototype_task("last prototype task")
  end

  test "repeat with service task process" do
    PS.clear_state()
    load()
    data = %{"count" => 0, "limit" => 2}

    {:ok, ppid, uid, _business_key} = PE.start_process("repeat with service task process", data)
    PE.execute(ppid)
    Process.sleep(100)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{"count" => 2, "limit" => 2}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 4
  end

  defprocess "repeat with subprocess task process" do
    repeat_task "repeat task", condition: :count_is_less_than_limit do
      service_task("add one to count 1", function: :add_1_to_count, inputs: "count")
      subprocess_task("subprocess task", model: "subprocess with one prototype test")
    end
    prototype_task("last prototype task")
  end

  defprocess "subprocess with one prototype test" do
    prototype_task("subprocess prototype task 1")
  end

  test "repeat with subprocess task process" do
    PS.clear_state()
    load()
    data = %{"count" => 0, "limit" => 2}

    {:ok, ppid, uid, _business_key} = PE.start_process("repeat with subprocess task process", data)
    PE.execute(ppid)
    Process.sleep(100)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{"count" => 2, "limit" => 2}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 4
  end

  defprocess "repeat with subprocess service task process" do
    repeat_task "repeat task", condition: :count_is_less_than_limit do
      subprocess_task("subprocess task", model: "subprocess with one service test")
    end
  end

  defprocess "subprocess with one service test" do
    service_task("add one to count 1", function: :add_1_to_count, inputs: "count")
  end

  test "repeat with subprocess service task process" do
    PS.clear_state()
    load()
    data = %{"count" => 0, "limit" => 2}

    {:ok, ppid, uid, _business_key} = PE.start_process("repeat with subprocess service task process", data)
    PE.execute(ppid)
    Process.sleep(100)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{"count" => 2, "limit" => 2}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 2
  end

  defprocess "repeat task process" do
    repeat_task "repeat task", condition: :count_is_less_than_limit do
      prototype_task("prototype task 1")
      prototype_task("prototype task 2")
      service_task("add one to count 1", function: :add_1_to_count, inputs: "count")
    end
    prototype_task("last prototype task")
  end

  test "repeat task process" do
    PS.clear_state()
    load()

    {:ok, ppid, uid, _business_key} = PE.start_process("repeat task process", %{"count" => 0, "limit" => 5})
    PE.execute(ppid)
    Process.sleep(100)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{"count" => 5, "limit" => 5}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 17
  end

  defprocess "two timer task process" do
    timer_task("one second timer task", duration: 1000)
    timer_task("two second timer task", duration: 2000)
  end

  test "two timer task process" do
    PS.clear_state()
    load()
    data = %{}

    {:ok, ppid, uid, _business_key} = PE.start_process("two timer task process", data)
    PE.execute(ppid)
    Process.sleep(4000)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 2
  end

  def no_quick_score(_data) do
    true
  end

  def do_nothing(_data) do
    true
  end

  defprocess "get credit rating" do
    prototype_task("get quick credit score")
    subprocess_task("credit rating subprocess task", model: "credit rating subprocess")
    prototype_task("user reviews credit score")
  end

  defprocess "credit rating subprocess" do
    case_task "no quick score available" do
      case_i :no_quick_score do
        prototype_task("get detailed credit score")
      end
      case_i :do_nothing do
        prototype_task("do notiing")
      end
    end
  end

  test "get credit rating" do
    PS.clear_state()
    load()
    data = %{}

    {:ok, ppid, uid, _business_key} = PE.start_process("get credit rating", data)
    PE.execute(ppid)
    Process.sleep(100)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 3
  end

  def receive_payment_details(msg) do
    case msg do
      {:payment_details, details} -> %{"payment_details" => details}
      {:payment_timeout, :order_id} -> %{"payment_timeout" => :order_id}
      {:order_canceled, :order_id} -> %{"order_canceled" => :order_id}
    end
  end

  def payment_period_expired(data) do
    Map.get(data, "payment_timeout")
  end

  def order_canceled(data) do
    Map.get(data, "order_canceled")
  end

  defprocess "act on one of multiple events" do
    prototype_task("create order")
    receive_task("receive payment details", selector: :receive_payment_details)
    reroute_task "payment period expired", condition: :payment_period_expired do
      prototype_task("cancel order due to timeout")
    end
    reroute_task "order canceled", condition: :order_canceled do
      prototype_task("cancel order due to order cancelation")
    end
    prototype_task("process payment")
  end

  test "act on one of multiple events" do
    PS.clear_state()
    load()
    data = %{"barrower_id" => "511-58-1422"}

    {:ok, ppid, uid, _business_key} = PE.start_process("act on one of multiple events", data)
    PE.execute(ppid)
    Process.sleep(100)

    assert PE.is_complete(ppid) == false

    PubSub.broadcast(:pubsub, "pe_topic", {:message, {:order_canceled, :order_id}})
    Process.sleep(100)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{"barrower_id" => "511-58-1422", "order_canceled" => :order_id}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 5
  end

  def receive_loan_income(msg) do
    case msg do
      {:barrower_income, income} -> %{"barrower_income" => income}
      _ -> nil
    end
  end

  defprocess "receive barrower income process" do
    receive_task("receive barrower income", selector: :receive_loan_income)
  end

  test "receive barrower income process" do
    PS.clear_state()
    load()
    data = %{"barrower_id" => "511-58-1422"}

    {:ok, ppid, uid, _business_key} = PE.start_process("receive barrower income process", data)
    PE.execute(ppid)
    Process.sleep(100)

    assert PE.is_complete(ppid) == false

    PubSub.broadcast(:pubsub, "pe_topic", {:message, {:barrower_income, 100_000}})
    Process.sleep(100)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{"barrower_income" => 100000, "barrower_id" => "511-58-1422"}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 1
  end

  defprocess "send barrower income process" do
    send_task("send barrower income", message: {:barrower_income, 100_000})
  end

  test "send and receive barrower income process" do
    PS.clear_state()
    load()
    data = %{"barrower_id" => "511-58-1422"}

    {:ok, r_ppid, r_uid, _business_key} = PE.start_process("receive barrower income process", data)
    PE.execute(r_ppid)
    Process.sleep(500)

    {:ok, s_ppid, _s_uid, _business_key} = PE.start_process("send barrower income process", %{})
    PE.execute(s_ppid)
    Process.sleep(500)

    completed_process = PS.get_completed_process(r_uid)
    assert completed_process.data == %{"barrower_income" => 100000, "barrower_id" => "511-58-1422"}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 1
  end

  def square(data) do
    Map.put(data, "square", data["x"] * data["x"])

  end

  defprocess "one service task process" do
    service_task("a service task", function: :square, inputs: "x")
  end

  test "one service task process" do
    PS.clear_state()
    load()
    data = %{"x" => 3}

    {:ok, ppid, uid, _business_key} = PE.start_process("one service task process", data)
    PE.execute(ppid)
    Process.sleep(100)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{"x" => 3, "square" => 9}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 1
  end

  defprocess "one service tuple task process" do
    service_task("a service task", function: :square, inputs: "x")
  end

  test "one service tuple task process" do
    PS.clear_state()
    load()
    data = %{"x" => 3}

    {:ok, ppid, uid, _business_key} = PE.start_process("one service tuple task process", data)
    PE.execute(ppid)
    Process.sleep(100)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{"x" => 3, "square" => 9}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 1
  end

  defprocess "two user task process" do
    user_task("add one to x 1", groups: "admin", outputs: "na")
    user_task("add one to x 2", groups: "admin", inputs: "x", outputs: "na")
  end

  test "two user task process" do
    PS.clear_state()
    load()
    data = %{}

    {:ok, ppid, _uid, _business_key} = PE.start_process("two user task process", data)
    PE.execute(ppid)
    Process.sleep(100)

    assert PE.is_complete(ppid) == false
  end

  defprocess "three user task process" do
    user_task("1", groups: "admin", outputs: "na")
    user_task("2", groups: "admin", inputs: "x,y", outputs: "na")
    user_task("3", groups: "admin", outputs: "na")
  end

  test "three user task process" do
    PS.clear_state()
    load()
    data = %{}

    {:ok, ppid, _uid, _business_key} = PE.start_process("three user task process", data)
    PE.execute(ppid)
    Process.sleep(100)

    assert PE.is_complete(ppid) == false
  end

  rule_table = """
  F     income      || status
  1     > 50000     || approved
  2     <= 49999    || declined
  """

  defprocess "single rule task process" do
    rule_task("loan decision", inputs: "income", rule_table: rule_table)
  end

  test "single rule task process" do
    PS.clear_state()
    load()
    data = %{"income" => 3000}

    {:ok, ppid, uid, _business_key} = PE.start_process("single rule task process", data)
    PE.execute(ppid)
    Process.sleep(100)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{"income" => 3000, "status" => "declined"}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 1
  end

  defprocess "two parallel routes process" do
    parallel_task "a parallel task" do
      route do
        user_task("1", groups: "admin", outputs: "na")
        user_task("2", groups: "admin", outputs: "na")
      end
      route do
        user_task("3", groups: "admin", outputs: "na")
        user_task("4", groups: "admin", outputs: "na")
      end
    end
  end

  test "two parallel routes process" do
    PS.clear_state()
    load()
    data = %{}

    {:ok, ppid, _uid, _business_key} = PE.start_process("two parallel routes process", data)
    PE.execute(ppid)

    assert PE.is_complete(ppid) == false
  end

  def x_less_than_y(data) do
    data["x"] < data["y"]
  end

  def x_greater_or_equal_y(data) do
    data["x"] >= data["y"]
  end

  defprocess "two case process" do
    case_task "yes or no" do
      case_i :x_less_than_y do
        user_task("1", groups: "admin", outputs: "na")
        user_task("2", groups: "admin", outputs: "na")
      end
      case_i :x_greater_or_equal_y do
        user_task("3", groups: "admin", outputs: "na")
        user_task("4", groups: "admin", outputs: "na")
      end
    end
  end

  test "two case process" do
    PS.clear_state()
    load()
    data = %{"x" => 1,"y" => 2}

    {:ok, ppid, _uid, _business_key} = PE.start_process("two case process", data)
    PE.execute(ppid)

    assert PE.is_complete(ppid) == false
  end

  def decide_loan(data) do
    decision = if data["income"] > 50_000, do: "Approved", else: "Declined"
    Map.put(data, "decision", decision)
  end

  def loan_approved(data) do
    data["decision"] == "Approved"
  end

  def loan_declined(data) do
    data["decision"] == "Declined"
  end

  def send_approval(_data) do
    IO.puts "Approval Sent"
    %{}
  end

  def send_decline(_data) do
    IO.puts "Decline Sent"
    %{}
  end

  defprocess "two service task case process" do
    service_task("decide loan approval", function: :decide_loan, inputs: "income")
    case_task "yes or no" do
      case_i :loan_approved do
        service_task("send approval notice", function: :send_approval, inputs: "income")
      end
      case_i :loan_declined do
        service_task("send decline notice", function: :send_decline, inputs: "income")
      end
    end
  end

  test "two service task case process" do
    PS.clear_state()
    load()
    data = %{"income" => 100_000}

    {:ok, ppid, uid, _business_key} = PE.start_process("two service task case process", data)
    PE.execute(ppid)
    Process.sleep(1000)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{"income" => 100000, "decision" => "Approved"}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 3
  end

  def add_one_to_value(data) do
    Map.put(data, "value", data["value"] + 1)
  end

  defprocess "two service tasks" do
    service_task("service task 1", function: :add_one_to_value, inputs: "value")
    service_task("service task 2", function: :add_one_to_value, inputs: "value")
  end

  defprocess "subprocess task process" do
    subprocess_task("subprocess task", model: "two service tasks")
  end

  test "subprocess task process" do
    PS.clear_state()
    load()
    data = %{"value" => 1}

    {:ok, ppid, uid, _business_key} = PE.start_process("subprocess task process", data)
    PE.execute(ppid)
    Process.sleep(1000)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{"value" => 3}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 1
  end

  defprocess "two prototype task process" do
    prototype_task("prototype task 1")
    prototype_task("prototype task 2")
  end

  test "two prototype task process" do
    PS.clear_state()
    load()
    data = %{}

    {:ok, ppid, uid, _business_key} = PE.start_process("two prototype task process", data)
    PE.execute(ppid)
    Process.sleep(1000)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 2
  end

end
