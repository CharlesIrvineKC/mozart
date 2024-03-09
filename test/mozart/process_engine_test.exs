defmodule Mozart.ProcessEngineTest do
  use ExUnit.Case

  alias Mozart.Util
  alias Mozart.ProcessEngine

  setup do
    state = Util.get_test_state()
    {:ok, server} = GenServer.start_link(ProcessEngine, state)
    %{server: server}
  end

  test "start server", %{server: server} do
    assert server != nil
  end
end
