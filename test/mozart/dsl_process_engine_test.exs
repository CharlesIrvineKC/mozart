defmodule Mozart.DslProcessEngineTest do
  use ExUnit.Case
  use Mozart.BpmProcess

  alias Phoenix.PubSub
  alias Mozart.ProcessEngine, as: PE
  alias Mozart.ProcessService, as: PS
  alias Mozart.DslProcessEngineTest, as: ME

  def continue(data) do
    data.continue
  end

  defprocess "repeat task process" do
    repeat_task "repeat task", &ME.continue/1 do
      prototype_task("prototype task 1")
      prototype_task("prototype task 2")
      user_task("user task", groups: "admin")
    end
    prototype_task("last prototype task")
  end

  test "repeat task process" do
    PS.clear_state()
    PS.load_process_models(get_processes())

    {:ok, ppid, uid, _process_key} = PE.start_process("repeat task process", %{continue: true})
    PE.execute(ppid)
    Process.sleep(100)

    user_task = hd(PS.get_user_tasks())
    PS.complete_user_task(uid, user_task.uid, %{continue: true})
    Process.sleep(100)

    user_task = hd(PS.get_user_tasks())
    PS.complete_user_task(uid, user_task.uid, %{continue: false})
  end

  defprocess "two timer task process" do
    timer_task("one second timer task", duration: 1000)
    timer_task("two second timer task", duration: 2000)
  end

  test "two timer task process" do
    PS.clear_state()
    PS.load_process_models(get_processes())
    data = %{}

    {:ok, ppid, uid, _process_key} = PE.start_process("two timer task process", data)
    PE.execute(ppid)
    Process.sleep(4000)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 2
  end

  def receive_loan_income(msg) do
    case msg do
      {:barrower_income, income} -> %{barrower_income: income}
      _ -> nil
    end
  end

  defprocess "receive barrower income process" do
    receive_task("receive barrower income", selector: &ME.receive_loan_income/1)
  end

  test "receive barrower income process" do
    PS.clear_state()
    PS.load_process_models(get_processes())
    data = %{barrower_id: "511-58-1422"}

    {:ok, ppid, uid, _process_key} = PE.start_process("receive barrower income process", data)
    PE.execute(ppid)
    Process.sleep(100)

    assert PE.is_complete(ppid) == false

    PubSub.broadcast(:pubsub, "pe_topic", {:message, {:barrower_income, 100_000}})
    Process.sleep(100)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{barrower_income: 100000, barrower_id: "511-58-1422"}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 1
  end

  defprocess "send barrower income process" do
    send_task("send barrower income", message: {:barrower_income, 100_000})
  end

  test "send and receive barrower income process" do
    PS.clear_state()
    PS.load_process_models(get_processes())
    data = %{barrower_id: "511-58-1422"}

    {:ok, r_ppid, r_uid, _process_key} = PE.start_process("receive barrower income process", data)
    PE.execute(r_ppid)
    Process.sleep(500)

    {:ok, s_ppid, _s_uid, _process_key} = PE.start_process("send barrower income process", %{})
    PE.execute(s_ppid)
    Process.sleep(500)

    completed_process = PS.get_completed_process(r_uid)
    assert completed_process.data == %{barrower_income: 100000, barrower_id: "511-58-1422"}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 1
  end

  def square(data) do
    Map.put(data, :square, data.x * data.x)
  end

  defprocess "one service task process" do
    service_task("a service task", function: &ME.square/1, inputs: "x")
  end

  test "one service task process" do
    PS.clear_state()
    PS.load_process_models(get_processes())
    data = %{x: 3}

    {:ok, ppid, uid, _process_key} = PE.start_process("one service task process", data)
    PE.execute(ppid)
    Process.sleep(100)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{x: 3, square: 9}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 1
  end

  defprocess "two user task process" do
    user_task("add one to x", groups: "admin")
    user_task("add one to x", groups: "admin", inputs: "x")
  end

  test "two user task process" do
    PS.clear_state()
    PS.load_process_models(get_processes())
    data = %{}

    {:ok, ppid, _uid, _process_key} = PE.start_process("two user task process", data)
    PE.execute(ppid)
    Process.sleep(100)

    assert PE.is_complete(ppid) == false
  end

  defprocess "three user task process" do
    user_task("1", groups: "admin")
    user_task("2", groups: "admin", inputs: "x,y")
    user_task("3", groups: "admin")
  end

  test "three user task process" do
    PS.clear_state()
    PS.load_process_models(get_processes())
    data = %{}

    {:ok, ppid, _uid, _process_key} = PE.start_process("three user task process", data)
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
    PS.load_process_models(get_processes())
    data = %{income: 3000}

    {:ok, ppid, uid, _process_key} = PE.start_process("single rule task process", data)
    PE.execute(ppid)
    Process.sleep(100)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{income: 3000, status: "declined"}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 1
  end

  defprocess "two parallel routes process" do
    parallel_task("a parallel task", [
      route do
        user_task("1", groups: "admin")
        user_task("2", groups: "admin")
      end,
      route do
        user_task("3", groups: "admin")
        user_task("4", groups: "admin")
      end
    ])
  end

  test "two parallel routes process" do
    PS.clear_state()
    PS.load_process_models(get_processes())
    data = %{}

    {:ok, ppid, _uid, _process_key} = PE.start_process("two parallel routes process", data)
    PE.execute(ppid)

    assert PE.is_complete(ppid) == false
  end

  def x_less_than_y(data) do
    data.x < data.y
  end

  def x_greater_or_equal_y(data) do
    data.x >= data.y
  end

  defprocess "two case process" do
    case_task("yes or no", [
      case_i &ME.x_less_than_y/1 do
        user_task("1", groups: "admin")
        user_task("2", groups: "admin")
      end,
      case_i &ME.x_greater_or_equal_y/1 do
        user_task("3", groups: "admin")
        user_task("4", groups: "admin")
      end
    ])
  end

  test "two case process" do
    PS.clear_state()
    PS.load_process_models(get_processes())
    data = %{x: 1, y: 2}

    {:ok, ppid, _uid, _process_key} = PE.start_process("two case process", data)
    PE.execute(ppid)

    assert PE.is_complete(ppid) == false
  end

  def decide_loan(data) do
    decision = if data.income > 50_000, do: "Approved", else: "Declined"
    Map.put(data, :decision, decision)
  end

  def loan_approved(data) do
    data.decision == "Approved"
  end

  def loan_declined(data) do
    data.decision == "Declined"
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
    service_task("decide loan approval", function: &ME.decide_loan/1, inputs: "income")
    case_task("yes or no", [
      case_i &ME.loan_approved/1 do
        service_task("send approval notice", function: &ME.send_approval/1, inputs: "income")
      end,
      case_i &ME.loan_declined/1 do
        service_task("send decline notice", function: &ME.send_decline/1, inputs: "income")
      end
    ])
  end

  test "two service task case process" do
    PS.clear_state()
    PS.load_process_models(get_processes())
    data = %{income: 100_000}

    {:ok, ppid, uid, _process_key} = PE.start_process("two service task case process", data)
    PE.execute(ppid)
    Process.sleep(1000)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{income: 100000, decision: "Approved"}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 3
  end

  def add_one_to_value(data) do
    Map.put(data, :value, data.value + 1)
  end

  defprocess "two service tasks" do
    service_task("service task 1", function: &ME.add_one_to_value/1, inputs: "value")
    service_task("service task 2", function: &ME.add_one_to_value/1, inputs: "value")
  end

  defprocess "subprocess task process" do
    subprocess_task("subprocess task", model: "two service tasks")
  end

  test "subprocess task process" do
    PS.clear_state()
    PS.load_process_models(get_processes())
    data = %{value: 1}

    {:ok, ppid, uid, _process_key} = PE.start_process("subprocess task process", data)
    PE.execute(ppid)
    Process.sleep(1000)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{value: 3}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 1
  end

  defprocess "two prototype task process" do
    prototype_task("prototype task 1")
    prototype_task("prototype task 2")
  end

  test "two prototype task process" do
    PS.clear_state()
    PS.load_process_models(get_processes())
    data = %{}

    {:ok, ppid, uid, _process_key} = PE.start_process("two prototype task process", data)
    PE.execute(ppid)
    Process.sleep(1000)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 2
  end

end
