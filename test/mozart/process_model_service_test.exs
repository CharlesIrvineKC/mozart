defmodule Mozart.ProcessModelServiceTest do
  use ExUnit.Case

  alias Mozart.Util
  alias Mozart.ProcessModelService

  setup do
    {:ok, _pid} = ProcessModelService.start_link(nil)

    Enum.each(Util.get_testing_process_models(), fn model ->
      ProcessModelService.load_process_model(model)
    end)
  end

  test "load a process model" do
    model = ProcessModelService.get_process_model(:simple_process_model)
    assert model.name == :simple_process_model
  end

end
