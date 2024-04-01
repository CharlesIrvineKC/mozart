defmodule Mozart.ProcessManagerTest do
  use ExUnit.Case

  alias Mozart.ProcessManager
  alias Mozart.UserManager
  alias Mozart.Util

  setup do
    simple_model = Util.get_simple_model()
    ProcessManager.start_link(nil)
    UserManager.start_link(nil)
    GenServer.cast(ProcessManager, {:load_process_model, simple_model})
    simple_data = %{foo: :foo}
    %{simple_data: simple_data, user_id: "crirvine"}
  end

  test "load a process model" do
    model = ProcessManager.get_process_model(:foo)
    assert model.name == :foo
  end

  test "start a simple process new", %{simple_data: simple_data} do
    process_id = ProcessManager.start_process(:foo, simple_data)
    assert process_id != nil
  end

  test "start a process and get its ppid", %{simple_data: simple_data} do
    process_id = ProcessManager.start_process(:foo, simple_data)
    process_pid = ProcessManager.get_process_ppid(process_id)
    assert process_pid != nil
  end

  test "get user tasks", %{user_id: user_id} do
    tasks = IO.inspect(ProcessManager.get_user_tasks(user_id))
    assert tasks == []
  end
end
