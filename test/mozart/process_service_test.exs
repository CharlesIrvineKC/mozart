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

  test "get user tasks for person" do
    UserService.insert_user(%User{name: "crirvine", groups: ["admin"]})
    tasks = ProcessService.get_user_tasks("crirvine")
    assert tasks == []
  end
end
