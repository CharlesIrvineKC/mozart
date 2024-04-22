defmodule Mozart.Util do
  alias Mozart.Data.Task
  alias Mozart.Data.ProcessModel

  def get_testing_process_models do
    [
      %ProcessModel{
        name: :call_process_model,
        tasks: [
          %Task{
            name: :call_process_task,
            type: :sub_process,
            sub_process: :subprocess_model,
            next: :bar
          },
          %Task{
            name: :bar,
            type: :user,
            assigned_groups: ["admin"],
            next: nil
          }
        ],
        initial_task: :call_process_task
      },
      %ProcessModel{
        name: :subprocess_model,
        tasks: [
          %Task{
            name: :service_task,
            type: :service,
            function: fn data -> Map.merge(data, %{service: :service}) end,
            next: nil
          }
        ],
        initial_task: :service_task
      },
      %ProcessModel{
        name: :choice_process_model,
        tasks: [
          %Task{
            name: :choice_task,
            type: :choice,
            choices: [
              %{
                expression: fn data -> data.value < 10 end,
                next: :foo
              },
              %{
                expression: fn data -> data.value >= 10 end,
                next: :bar
              }
            ]
          },
          %Task{
            name: :foo,
            type: :service,
            function: fn data -> Map.merge(data, %{foo: :foo}) end,
            next: nil
          },
          %Task{
            name: :bar,
            type: :service,
            function: fn data -> Map.merge(data, %{bar: :bar}) end,
            next: nil
          }
        ],
        initial_task: :choice_task
      },
      %ProcessModel{
        name: :simple_process_model,
        tasks: [
          %Task{
            name: :foo,
            type: :service,
            function: fn data -> Map.merge(data, %{bar: :bar}) end,
            next: nil
          }
        ],
        initial_task: :foo
      },
      %ProcessModel{
        name: :user_task_process_model,
        tasks: [
          %Task{
            name: :foo,
            type: :user,
            assigned_groups: ["admin"],
            next: nil
          }
        ],
        initial_task: :foo
      },
      %ProcessModel{
        name: :user_task_then_service,
        tasks: [
          %Task{
            name: :user_task_1,
            type: :user,
            assigned_groups: ["admin"],
            next: :increment_by_one_task
          },
          %Task{
            name: :increment_by_one_task,
            type: :service,
            function: fn map -> Map.put(map, :value, map.value + 1) end,
            next: nil
          }
        ],
        initial_task: :user_task_1
      },
      %ProcessModel{
        name: :service_then_user_task,
        tasks: [
          %Task{
            name: :increment_by_one_task,
            type: :service,
            function: fn map -> Map.put(map, :value, map.value + 1) end,
            next: :user_task_1
          },
          %Task{
            name: :user_task_1,
            type: :user,
            assigned_groups: ["admin"],
            next: nil
          }
        ],
        initial_task: :increment_by_one_task
      },
      %ProcessModel{
        name: :increment_by_one_process,
        tasks: [
          %Task{
            name: :increment_by_one_task,
            type: :service,
            function: fn map -> Map.put(map, :value, map.value + 1) end,
            next: nil
          }
        ],
        initial_task: :increment_by_one_task
      },
      %ProcessModel{
        name: :increment_by_one_twice_process,
        tasks: [
          %Task{
            name: :increment_by_one_task,
            type: :service,
            function: fn map -> Map.put(map, :value, map.value + 1) end,
            next: :increment_by_two_task
          },
          %Task{
            name: :increment_by_two_task,
            type: :service,
            function: fn map -> Map.put(map, :value, map.value + 2) end,
            next: nil
          }
        ],
        initial_task: :increment_by_one_task
      },
      %ProcessModel{
        name: :three_increment_by_one_process,
        tasks: [
          %Task{
            name: :increment_by_one_task,
            type: :service,
            function: fn map -> Map.put(map, :value, map.value + 1) end,
            next: :increment_by_two_task
          },
          %Task{
            name: :increment_by_two_task,
            type: :service,
            function: fn map -> Map.put(map, :value, map.value + 2) end,
            next: :increment_by_three_task
          },
          %Task{
            name: :increment_by_three_task,
            type: :service,
            function: fn map -> Map.put(map, :value, map.value + 3) end,
            next: nil
          }
        ],
        initial_task: :increment_by_one_task
      }
    ]
  end
end
