defmodule Mozart.ProcessModelServiceTest do
  use ExUnit.Case

  alias Mozart.Util
  alias Mozart.ProcessModelService, as: PMS

  test "load a process model" do
    PMS.clear_then_load_process_models(Util.get_testing_process_models())
    model = PMS.get_process_model(:simple_process_model)
    assert model.name == :simple_process_model
  end

end
