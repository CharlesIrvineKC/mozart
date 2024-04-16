defmodule Mozart.ProcessServiceTest do
  use ExUnit.Case

  alias Mozart.ProcessService
  alias Mozart.UserService
  alias Mozart.UserTaskService
  alias Mozart.Util
  alias Mozart.Data.User

  setup do
    {:ok, _pid} = ProcessService.start_link(nil)
    Enum.each(Util.get_testing_process_models(), fn model -> ProcessService.load_process_model(model) end)
    {:ok, _pid} = UserService.start_link(nil)
    {:ok, _pid} = UserTaskService.start_link([])

    %{ok: nil}
  end

  test "load a process model" do
    model = ProcessService.get_process_model(:simple_process_model)
    ProcessService.load_process_model(model)

    model = ProcessService.get_process_model(:simple_process_model)
    assert model.name == :simple_process_model
  end

  test "start a simple process new" do
    model = ProcessService.get_process_model(:simple_process_model)
    ProcessService.load_process_model(model)

    process_id = ProcessService.start_process(:simple_process_model, %{foo: :foo})
    assert process_id != nil
  end

  test "start a process and get its ppid" do
    model = ProcessService.get_process_model(:simple_process_model)
    ProcessService.load_process_model(model)

    process_id = ProcessService.start_process(:simple_process_model, %{foo: :foo})
    process_pid = ProcessService.get_process_ppid(process_id)
    assert process_pid != nil
  end

  test "get user tasks for person" do
    UserService.insert_user(%User{name: "crirvine", groups: ["admin"]})
    tasks = ProcessService.get_user_tasks("crirvine")
    assert tasks == []
  end
end
