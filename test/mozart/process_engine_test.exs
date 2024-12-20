defmodule Mozart.ProcessEngineTest do
  use ExUnit.Case

  use Mozart.BpmProcess

  alias Phoenix.PubSub
  alias Mozart.ProcessEngine, as: PE
  alias Mozart.ProcessService, as: PS

  alias Mozart.Type.Number
  alias Mozart.Type.Choice
  alias Mozart.Type.MultiChoice
  alias Mozart.Type.Confirm

  defp get_first_task_from_state(ppid) do
    PE.get_state(ppid)
    |> Map.get(:execution_frames)
    |> hd()
    |> Map.get(:open_tasks)
    |> Map.values()
    |> hd()
  end

  defprocess "a user task process" do
    user_task("a user task", group: "Admin")
  end

  test "add process note from service" do
    PS.clear_state()
    load()
    {:ok, ppid, _uid, _business_key1} = PE.start_process("a user task process", %{})
    PE.execute(ppid)
    Process.sleep(100)

    user_task = get_first_task_from_state(ppid)

    note = PS.add_process_note(user_task.uid, "foobar@opera.com", "a sample note")

    assert PE.get_state(ppid) |> Map.get(:notes) |> Map.get(note.uid) == note
  end

  test "add process note" do
    PS.clear_state()
    load()
    {:ok, ppid, _uid, _business_key1} = PE.start_process("a user task process", %{})
    PE.execute(ppid)
    Process.sleep(100)

    note = PE.add_process_note(ppid, "my task", "john.doe@mozart.com", "some note text")
    assert %Mozart.Data.Note{
             uid: _uid,
             task_name: "my task",
             author: "john.doe@mozart.com",
             timestamp: _timestamp,
             text: "some note text"
           } = note

    note = %{note | text: "some new text"}
    assert %Mozart.Data.Note{
             uid: _uid,
             task_name: "my task",
             author: "john.doe@mozart.com",
             timestamp: _timestamp,
             text: "some new text"
           } = PE.update_process_note(ppid, note)

    user_task = get_first_task_from_state(ppid)
    assert PS.get_process_notes(user_task.uid) |> map_size() == 1

  end

  def receive_selector(msg, data) do
    case msg do
      %{"Customer Name" => name, "Phone Number" => phone_number} ->
        if name == data["Customer Name"] do
          %{"Phone Number" => phone_number}
        end

      _ ->
        nil
    end
  end

  defprocess "receive process" do
    receive_task("receive_task 1", selector: :receive_selector)
    receive_task("receive_task 2", selector: :receive_selector)
  end

  defprocess "send process 1" do
    send_task("send task",
      message: %{"Customer Name" => "Charles Irvine", "Phone Number" => "800 328 0022"}
    )
  end

  defprocess "send process 2" do
    send_task("send task", generator: :build_message)
  end

  def build_message(data) do
    %{"Customer Name" => data["Customer Name"], "Phone Number" => data["Phone Number"]}
  end

  test "receive a send message" do
    PS.clear_state()
    load()

    r_data = %{"Customer Name" => "Charles Irvine"}
    {:ok, r_ppid, r_uid, _business_key1} = PE.start_process("receive process", r_data)
    PE.execute(r_ppid)
    Process.sleep(100)

    s_data_1 = %{}
    {:ok, s_ppid_1, s_uid_1, _business_key1} = PE.start_process("send process 1", s_data_1)
    PE.execute(s_ppid_1)
    Process.sleep(100)

    s_data_2 = %{"Customer Name" => "Charles Irvine", "Phone Number" => "800 328 0022"}
    {:ok, s_ppid_2, s_uid_2, _business_key1} = PE.start_process("send process 2", s_data_2)
    PE.execute(s_ppid_2)
    Process.sleep(100)

    completed_process = PS.get_completed_process(r_uid)
    assert length(completed_process.completed_tasks) == 2

    completed_process = PS.get_completed_process(s_uid_1)
    assert length(completed_process.completed_tasks) == 1

    completed_process = PS.get_completed_process(s_uid_2)
    assert length(completed_process.completed_tasks) == 1
  end

  def reroute_is_true(data) do
    data.reroute
  end

  defprocess "reroute process" do
    prototype_task("initial prototype task")

    reroute_task "reroute task", condition: :reroute_is_true do
      prototype_task("rerouted prototype task")
    end

    prototype_task("final prototype task", foobar: true)
  end

  test "reroute process" do
    PS.clear_state()
    load()
    data = %{reroute: true}

    {:ok, ppid, uid, _business_key1} = PE.start_process("reroute process", data)
    PE.execute(ppid)

    Process.sleep(100)

    completed_process = PS.get_completed_process(uid)

    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 3
  end

  def case_1(_data) do
    true
  end

  def case_2(_data) do
    true
  end

  def count_is_greater_than_1(data) do
    data[:count] < 1
  end

  defprocess "Case Process" do
    prototype_task("First Prototype Task")

    case_task "Case Task" do
      case_i :case_1 do
        prototype_task("Case 1 prototype task")
        subprocess_task("Subprocess Task", process: "Case Subprocess")
      end

      case_i :case_2 do
        prototype_task("Case 2 Prototype Task")
      end
    end
  end

  defprocess "Case Subprocess" do
    repeat_task "Repeat Task", condition: :count_is_greater_than_1 do
      prototype_task("Repeated Prototype Task", %{count: 1})
    end
  end

  test "Case Process" do
    PS.clear_state()
    load()
    data = %{count: 0}

    {:ok, ppid, uid, _business_key1} = PE.start_process("Case Process", data)
    PE.execute(ppid)

    Process.sleep(100)

    completed_process = PS.get_completed_process(uid)

    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 6
  end

  defprocess "Simple Process with User Task" do
    user_task("User Task", groups: "Foobar")
  end

  test "Simple Process with User Task" do
    PS.clear_state()
    load()

    {:ok, ppid, _uid, _business_key1} = PE.start_process("Simple Process with User Task", %{})
    PE.execute(ppid)

    Process.sleep(100)

    assert PE.get_state(ppid).top_level_process == "Simple Process with User Task"
  end

  defprocess "Top Level Process" do
    subprocess_task("Subprocess Task", process: "Subprocess")
    prototype_task("Final prototype task")
  end

  defprocess "Subprocess" do
    prototype_task("Prototype Task in Subprocess")
  end

  test "Simple Subprocess" do
    PS.clear_state()
    load()

    {:ok, ppid, uid, _business_key1} = PE.start_process("Subprocess", %{})
    PE.execute(ppid)

    Process.sleep(600)

    completed_process = PS.get_completed_process(uid)

    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 1
  end

  test "Top Level Process" do
    PS.clear_state()
    load()

    {:ok, ppid, uid, _business_key1} = PE.start_process("Top Level Process", %{})
    PE.execute(ppid)

    Process.sleep(600)

    completed_process = PS.get_completed_process(uid)

    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 3
  end

  test "Prepare and Deliver Pizza" do
    PS.clear_state()
    load()

    {:ok, ppid, uid, _business_key1} = PE.start_process("Prepare and Deliver Pizza", %{})
    PE.execute(ppid)

    Process.sleep(600)

    completed_process = PS.get_completed_process(uid)

    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 2
  end

  def schedule_timer_expiration(task_uid, process_uid, timer_duration) do
    spawn(fn -> wait_and_notify(task_uid, process_uid, timer_duration) end)
  end

  defprocess "Pizza Order" do
    subprocess_task("Prepare and Deliver Subprocess Task", process: "Prepare and Deliver Pizza")
  end

  defprocess "Prepare and Deliver Pizza" do
    timer_task("Prepare Pizza", duration: 200, function: :schedule_timer_expiration)
    timer_task("Deliver Pizza", duration: 200, function: :schedule_timer_expiration)
  end

  def_task_exit_event "Cancel Pizza Order",
    process: "Pizza Order",
    exit_task: "Prepare and Deliver Subprocess Task",
    selector: :exit_subprocess_task_event_selector do
    prototype_task("Cancel Preparation")
    prototype_task("Cancel Delivery")
  end

  def exit_subprocess_task_event_selector(event) do
    event == :exit_subprocess_task
  end

  def send_timer_expired(task_uid, process_uid) do
    ppid = PS.get_process_pid_from_uid(process_uid)
    if ppid, do: send(ppid, {:timer_expired, task_uid})
  end

  defp wait_and_notify(task_uid, process_uid, timer_duration) do
    :timer.apply_after(timer_duration, __MODULE__, :send_timer_expired, [task_uid, process_uid])
  end

  defprocess "process to test user assignment" do
    user_task("a user task to assign user", groups: "Admin")
  end

  test "process to test user assignment" do
    PS.clear_state()
    load()

    {:ok, ppid, _uid, _business_key} =
      PE.start_process("process to test user assignment", %{})

    PE.execute(ppid)
    Process.sleep(100)

    user_task = hd(PS.get_user_tasks())

    PS.assign_user_task(user_task.uid, "foobar@foo.bar.com")
    Process.sleep(100)

    user_task = hd(PS.get_user_tasks())

    assert user_task.assigned_user == "foobar@foo.bar.com"

    user_task = Map.get(PE.get_open_tasks(ppid), user_task.uid)

    assert user_task.assigned_user == "foobar@foo.bar.com"
  end

  def_bpm_application("test bpm app", data: "foo, bar", bk_prefix: "bar,foo")

  test "test bpm app" do
    PS.clear_state()
    load()

    apps = PS.get_bpm_applications()
    {"test bpm app", app} = hd(apps)
    assert app.module == Mozart.ProcessEngineTest
    assert Enum.frequencies(app.groups) == Enum.frequencies(["Admin", "Customer Service"])
  end

  defprocess "user task has top level model name" do
    user_task("a user task", group: "Customer Service")
  end

  defprocess "top level process" do
    subprocess_task("a subprocess task", process: "user task has top level model name")
  end

  test "top level process" do
    PS.clear_state()
    load()
    data = %{}

    {:ok, ppid, _uid, _business_key} = PE.start_process("top level process", data)

    PE.execute(ppid)
    Process.sleep(100)

    user_task = hd(PS.get_user_tasks())
    assert user_task.name == "a user task"
    assert PE.get_state(ppid) |> Map.get(:execution_frames) |> length() == 2
  end

  def assign_user(user_task, data) do
    Map.put(user_task, :assigned_user, data["Assigned User"])
  end

  defprocess "user task with listener" do
    user_task("a user task", listener: :assign_user)
  end

  test "user task with listener" do
    PS.clear_state()
    load()
    data = %{"Assigned User" => "admin@opera.com"}

    {:ok, ppid, _uid, _business_key} =
      PE.start_process("user task with listener", data)

    PE.execute(ppid)
    Process.sleep(100)

    user_task = hd(PS.get_user_tasks())

    assert user_task.assigned_user == "admin@opera.com"
  end

  def while_count_less_than(data) do
    data["count"] < 1
  end

  def true_condition(_data) do
    true
  end

  def add_one_to_count(data) do
    %{"count" => data["count"] + 1}
  end

  defprocess "repeat conditional task" do
    repeat_task "repeat subprocess then conditional", condition: :while_count_less_than do
      service_task("add 1 to count", function: :add_one_to_count, inputs: "count")

      conditional_task "always execute", condition: :true_condition do
        user_task("a user task", group: "Admin", outputs: "foobar")
      end
    end
  end

  test "repeat conditional task" do
    PS.clear_state()
    load()
    data = %{"count" => 0}

    {:ok, ppid, uid, _business_key} =
      PE.start_process("repeat conditional task", data)

    PE.execute(ppid)
    Process.sleep(100)

    user_task = hd(PS.get_user_tasks())
    PS.complete_user_task(user_task.uid, %{foobar: :foobar})
    Process.sleep(200)

    assert length(PS.get_user_tasks()) == 0

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{:foobar => :foobar, "count" => 1}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 4
  end

  def do_conditional_tasks(_data) do
    true
  end

  defprocess "process with conditional task with user subtask" do
    prototype_task("initial task")

    conditional_task "a conditional task", condition: :do_conditional_tasks do
      prototype_task("first prototype task")
      user_task("last user task", group: "Admin", outputs: "My Outputs")
    end

    prototype_task("final prototype task")
  end

  test "process with conditional task with user subtask" do
    PS.clear_state()
    load()
    data = %{}

    {:ok, ppid, uid, _business_key} =
      PE.start_process("process with conditional task with user subtask", data)

    PE.execute(ppid)
    Process.sleep(100)

    user_task = hd(PS.get_user_tasks())
    PS.complete_user_task(user_task.uid, %{foobar: :foobar})
    Process.sleep(200)

    assert length(PS.get_user_tasks()) == 0

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{foobar: :foobar}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 5
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

    {:ok, ppid, uid, _business_key} = PE.start_process("parallel prototype tasks", data)
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

    completed_process = PS.get_completed_process(uid)
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
               type: :multi_choice
             }

    assert PS.get_type("confirm param") == %Confirm{param_name: "confirm param", type: :confirm}
  end

  defprocess "one user task process" do
    user_task("add one to x 1", group: "Admin", outputs: "x")
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

  defprocess "exit a subprocess task" do
    subprocess_task("subprocess task", process: "subprocess process")
  end

  defprocess "subprocess process" do
    timer_task("subprocess timer task", duration: 2000, function: :schedule_timer_expiration)
  end

  def_task_exit_event "exit subprocess task",
    process: "exit a subprocess task",
    exit_task: "subprocess task",
    selector: :exit_subprocess_task_event_selector do
    prototype_task("prototype task upon task exit")
  end

  # test "exit a subprocess task" do
  #   PS.clear_state()
  #   load()
  #   data = %{}

  #   {:ok, ppid, uid, _business_key} = PE.start_process("exit a subprocess task", data)
  #   PE.execute(ppid)
  #   Process.sleep(100)

  #   send(ppid, {:exit_task_event, :exit_subprocess_task})
  #   Process.sleep(3000)

  #   completed_process = PS.get_completed_process(uid)
  #   assert completed_process.data == %{}
  #   assert completed_process.complete == true
  #   assert length(completed_process.completed_tasks) == 2
  # end

  def exit_user_task_event_selector(message) do
    case message do
      :exit_user_task -> true
      _ -> nil
    end
  end

  defprocess "exit a user task" do
    user_task("user task", group: "Admin", outputs: "na")
  end

  def_task_exit_event "exit loan decision",
    process: "exit a user task",
    exit_task: "user task",
    selector: :exit_user_task_event_selector do
    prototype_task("prototype task 1")
    prototype_task("prototype task 2")
  end

  test "exit a user task 1" do
    PS.clear_state()
    load()
    data = %{}

    {:ok, ppid, uid, _business_key} = PE.start_process("exit a user task", data)
    PE.execute(ppid)
    Process.sleep(100)

    PubSub.broadcast(:pubsub, "pe_topic", {:exit_task_event, :exit_user_task})
    Process.sleep(100)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 3
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
      subprocess_task("subprocess task", process: "subprocess with one prototype test")
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

    {:ok, ppid, uid, _business_key} =
      PE.start_process("repeat with subprocess task process", data)

    PE.execute(ppid)
    Process.sleep(100)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{"count" => 2, "limit" => 2}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 8
  end

  defprocess "repeat with subprocess service task process" do
    repeat_task "repeat task", condition: :count_is_less_than_limit do
      subprocess_task("subprocess task", process: "subprocess with one service test")
    end
  end

  defprocess "subprocess with one service test" do
    service_task("add one to count 1", function: :add_1_to_count, inputs: "count")
  end

  def count_is_less_than_limit(data) do
    data["count"] < data["limit"]
  end

  test "repeat with subprocess service task process" do
    PS.clear_state()
    load()
    data = %{"count" => 0, "limit" => 2}

    {:ok, ppid, uid, _business_key} =
      PE.start_process("repeat with subprocess service task process", data)

    PE.execute(ppid)
    Process.sleep(100)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{"count" => 2, "limit" => 2}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 5
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

    {:ok, ppid, uid, _business_key} =
      PE.start_process("repeat task process", %{"count" => 0, "limit" => 5})

    PE.execute(ppid)
    Process.sleep(100)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{"count" => 5, "limit" => 5}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 17
  end

  defprocess "two timer task process" do
    timer_task("one second timer task", duration: 1000, function: :schedule_timer_expiration)
    timer_task("two second timer task", duration: 2000, function: :schedule_timer_expiration)
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
    subprocess_task("credit rating subprocess task", process: "credit rating subprocess")
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
    assert length(completed_process.completed_tasks) == 5
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

  # test "act on one of multiple events" do
  #   PS.clear_state()
  #   load()
  #   data = %{"barrower_id" => "511-58-1422"}

  #   {:ok, ppid, uid, _business_key} = PE.start_process("act on one of multiple events", data)
  #   PE.execute(ppid)
  #   Process.sleep(100)

  #   assert PE.is_complete(ppid) == false

  #   PubSub.broadcast(:pubsub, "pe_topic", {:message, {:order_canceled, :order_id}})
  #   Process.sleep(100)

  #   completed_process = PS.get_completed_process(uid)

  #   assert completed_process.data == %{
  #            "barrower_id" => "511-58-1422",
  #            "order_canceled" => :order_id
  #          }

  #   assert completed_process.complete == true
  #   assert length(completed_process.completed_tasks) == 5
  # end

  def receive_loan_income(msg, state_data) do
    case msg do
      %{"Barrower Income" => income, "Barrower ID" => id} ->
        if state_data["Barrower ID"] == id do
          %{"Barrower Income" => income}
        end

      _ ->
        nil
    end
  end

  defprocess "receive barrower income process" do
    receive_task("receive barrower income", selector: :receive_loan_income)
  end

  test "receive barrower income process" do
    PS.clear_state()
    load()
    data = %{"Barrower ID" => "511-58-1422"}

    {:ok, ppid, uid, _business_key} = PE.start_process("receive barrower income process", data)
    PE.execute(ppid)
    Process.sleep(100)

    assert PE.is_complete(ppid) == false

    PubSub.broadcast(
      :pubsub,
      "pe_topic",
      {:message, %{"Barrower Income" => 100_000, "Barrower ID" => "511-58-1422"}}
    )

    Process.sleep(100)

    completed_process = PS.get_completed_process(uid)

    assert completed_process.data == %{
             "Barrower Income" => 100_000,
             "Barrower ID" => "511-58-1422"
           }

    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 1
  end

  defprocess "send barrower income process" do
    send_task("send barrower income", message: {:barrower_income, 100_000})
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
    user_task("add one to x 1", group: "Admin", outputs: "na")
    user_task("add one to x 2", group: "Admin", inputs: "x", outputs: "na")
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
    user_task("1", group: "Admin", outputs: "na")
    user_task("2", group: "Admin", inputs: "x,y", outputs: "na")
    user_task("3", group: "Admin", outputs: "na")
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
        user_task("1", group: "Admin", outputs: "na")
        user_task("2", group: "Admin", outputs: "na")
      end

      route do
        user_task("3", group: "Admin", outputs: "na")
        user_task("4", group: "Admin", outputs: "na")
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
        user_task("1", group: "Admin", outputs: "na")
        user_task("2", group: "Admin", outputs: "na")
      end

      case_i :x_greater_or_equal_y do
        user_task("3", group: "Admin", outputs: "na")
        user_task("4", group: "Admin", outputs: "na")
      end
    end
  end

  test "two case process" do
    PS.clear_state()
    load()
    data = %{"x" => 1, "y" => 2}

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
    %{}
  end

  def send_decline(_data) do
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
    Process.sleep(500)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{"income" => 100_000, "decision" => "Approved"}
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
    subprocess_task("subprocess task", process: "two service tasks")
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
    assert length(completed_process.completed_tasks) == 3
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
