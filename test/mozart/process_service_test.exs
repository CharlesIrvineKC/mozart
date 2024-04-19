defmodule Mozart.ProcessServiceTest do
  use ExUnit.Case

  alias Mozart.ProcessService
  alias Mozart.ProcessModelService
  alias Mozart.UserService
  alias Mozart.UserTaskService
  alias Mozart.Util
  alias Mozart.Data.User

  setup do
    {:ok, _pid} = ProcessService.start_link(nil)
    {:ok, _pid} = ProcessModelService.start_link(nil)

    Enum.each(Util.get_testing_process_models(), fn model ->
      ProcessModelService.load_process_model(model)
    end)

    {:ok, _pid} = UserService.start_link(nil)
    {:ok, _pid} = UserTaskService.start_link([])

    %{ok: nil}
  end

  # test "start simple subprocess" do
  #   ProcessService.start_process(:call_process_model, %{foo: :foo})
  #   IO.inspect(ProcessService.get_process_instances())
  # end

  test "start a process and get its ppid" do
    process_uid = ProcessService.start_process(:simple_process_model, %{foo: :foo})
    process_pid = ProcessService.get_process_ppid(process_uid)
    assert process_pid != nil
  end

  test "get user tasks for person" do
    UserService.insert_user(%User{name: "crirvine", groups: ["admin"]})
    tasks = ProcessService.get_user_tasks("crirvine")
    assert tasks == []
  end
end
