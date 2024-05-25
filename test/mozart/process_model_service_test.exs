defmodule Mozart.ProcessModelServiceTest do
  use ExUnit.Case

  alias Mozart.Models.TestModels
  alias Mozart.ProcessModelService, as: PMS
  alias Mozart.Data.ProcessModel
  alias Mozart.Task.Subprocess

  test "clear and load a process model" do
    PMS.clear_then_load_process_models(TestModels.get_testing_process_models())
    model = PMS.get_process_model(:simple_process_model)
    assert model.name == :simple_process_model
  end

  test "load a process model" do
    model = %ProcessModel{
      name: :simple_call_process_model,
      tasks: [
        %Subprocess{
          name: :call_process_task,
          sub_process: :one_user_task_process
        }
      ],
      initial_task: :call_process_task
    }
    PMS.load_process_model(model)
    model = PMS.get_process_model(:simple_call_process_model)
    assert model.name == :simple_call_process_model
  end

end
