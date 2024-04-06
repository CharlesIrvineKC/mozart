defmodule Mozart.ProcessManagerTest do
  use ExUnit.Case

  alias Mozart.ProcessManager
  alias Mozart.UserManager
  alias Mozart.Util
  alias Mozart.Data.User

  setup do
    ProcessManager.start_link(nil)
    UserManager.start_link(nil)
    %{ok: nil}
  end

  test "load a process model" do
    ProcessManager.load_process_model(Util.get_simple_model())

    model = ProcessManager.get_process_model(:foo)
    assert model.name == :foo
  end

  test "start a simple process new" do
    ProcessManager.load_process_model(Util.get_simple_model())

    process_id = ProcessManager.start_process(:foo, %{foo: :foo})
    
    assert process_id != nil
  end

  test "start a process and get its ppid" do
    ProcessManager.load_process_model(Util.get_simple_model())

    process_id = ProcessManager.start_process(:foo, %{foo: :foo})
    process_pid = ProcessManager.get_process_ppid(process_id)
    assert process_pid != nil
  end

  test "get empty user tasks" do
    UserManager.insert_user(%User{name: "crirvine", groups: ["admin"]})
    tasks = ProcessManager.get_user_tasks("crirvine")
    assert tasks == []
  end
end
