defmodule Mozart.ProcessManagerTest do
  use ExUnit.Case

  alias Mozart.ProcessManager
  alias Mozart.UserManager
  alias Mozart.Util
  alias Mozart.Data.User

  setup do
    ProcessManager.start_link(nil)

    Enum.each(Util.get_testing_process_models(), fn model -> ProcessManager.load_process_model(model) end)
    UserManager.start_link(nil)
    %{ok: nil}
  end

  test "load a process model" do
    model = ProcessManager.get_process_model(:simple_process_model)
    ProcessManager.load_process_model(IO.inspect(model))

    model = ProcessManager.get_process_model(:simple_process_model)
    assert model.name == :simple_process_model
  end

  test "start a simple process new" do
    model = ProcessManager.get_process_model(:simple_process_model)
    ProcessManager.load_process_model(IO.inspect(model))

    process_id = ProcessManager.start_process(:simple_process_model, %{foo: :foo})
    assert process_id != nil
  end

  test "start a process and get its ppid" do
    model = ProcessManager.get_process_model(:simple_process_model)
    ProcessManager.load_process_model(IO.inspect(model))

    process_id = ProcessManager.start_process(:simple_process_model, %{foo: :foo})
    process_pid = ProcessManager.get_process_ppid(process_id)
    assert process_pid != nil
  end

  test "get empty user tasks" do
    UserManager.insert_user(%User{name: "crirvine", groups: ["admin"]})
    tasks = ProcessManager.get_user_tasks("crirvine")
    assert tasks == []
  end
end
