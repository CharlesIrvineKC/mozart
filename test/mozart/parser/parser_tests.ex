defmodule Mozart.Parser.ParserTests do
  use ExUnit.Case

  alias Mozart.Task.Choice
  alias Mozart.Task.User
  alias Mozart.Task.Script
  alias Mozart.Task.Subprocess
  alias Mozart.Data.ProcessModel

  def get_models do
    [
      %ProcessModel{
        name: :top_level_process,
        initial_task: :subprocess_task,
        tasks: [
          %Subprocess{
            name: :subprocess_task,
            sub_process_model_name: :top_subprocess,
            next: :service_task
          },
          %Script{
            name: :service_task,
            function: fn data -> Map.put(data, :value, data.value + 1) end,
            next: :user_task
          },
          %User{
            name: :a_user_task,
            assigned_groups: ["admin"]
          }
        ]
      },
      %ProcessModel{
        name: :top_subprocess,
        initial_task: :service_task_1,
        tasks: [
          %Script{
            name: :service_task_1,
            function: fn data -> Map.put(data, :value, data.value + 1) end,
            next: :choice_process_task
          },
          %Subprocess{
            name: :choice_process_task,
            sub_process_model_name: :choice_process
          }
        ]
      },
      %ProcessModel{
        name: :choice_process,
        initial_task: :choice_task,
        tasks: [
          %Choice{
            name: :choice_task,
            choices: [
              %{
                expression: fn data -> data.value < 10 end,
                next: :is_low_service
              },
              %{
                expression: fn data -> data.value >= 10 end,
                next: is_high_service
              }
            ]
          },
          %Script{
            name: :is_low_service,
            function: fn data -> Map.put(data, :is_high, false) end
          },
          %Script{
            name: :is_high_service,
            funcgtion: fn data -> Map.put(data, :is_high, true) end
          }
        ]
      }
    ]
  end
end
