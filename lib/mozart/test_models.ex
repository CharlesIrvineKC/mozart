defmodule Mozart.TestModels do
  alias Mozart.Data.Task
  alias Mozart.Data.ProcessModel
  alias Mozart.Services.RestService

  def call_process_receive_event_task do
    [
      %ProcessModel{
        name: :process_with_receive_event_task,
        tasks: [
          %Task{
            name: :receive_event_task,
            type: :receive_event,
            next: :nil
          }
        ],
        initial_task: :receive_event_task
      }
    ]
  end

  def call_timer_tasks do
    [
      %ProcessModel{
        name: :call_timer_task,
        tasks: [
          %Task{
            name: :wait_1_seconds,
            type: :timer,
            timer_duration: 1000,
            next: :wait_3_seconds
          },
          %Task{
            name: :wait_3_seconds,
            type: :timer,
            timer_duration: 3000,
            next: nil
          }
        ],
        initial_task: :wait_1_seconds
      }
    ]
  end

  def call_exteral_services do
    [
      %ProcessModel{
        name: :call_external_services,
        tasks: [
          %Task{
            name: :get_cat_facts,
            type: :service,
            function: fn data -> Map.merge(data, %{cat_facts: RestService.get_cat_facts()}) end,
            next: nil
          }
        ],
        initial_task: :get_cat_facts
      }
    ]
  end

  def get_parallel_process_models do
    [
      %ProcessModel{
        name: :parallel_process_model,
        tasks: [
          %Task{
            name: :parallel_task,
            type: :parallel,
            multi_next: [:foo, :bar]
          },
          %Task{
            name: :foo,
            type: :service,
            function: fn data -> Map.merge(data, %{foo: :foo}) end,
            next: :join_task
          },
          %Task{
            name: :bar,
            type: :service,
            function: fn data -> Map.merge(data, %{bar: :bar}) end,
            next: :foo_bar
          },
          %Task{
            name: :foo_bar,
            type: :service,
            function: fn data -> Map.merge(data, %{foo_bar: :foo_bar}) end,
            next: :join_task
          },
          %Task{
            name: :join_task,
            type: :join,
            inputs: [:foo, :foo_bar],
            next: :final_service
          },
          %Task{
            name: :final_service,
            type: :service,
            function: fn data -> Map.merge(data, %{final: :final}) end,
            next: nil
          }
        ],
        initial_task: :parallel_task
      }
    ]
  end

  def get_complex_process_models do
    [
      %ProcessModel{
        name: :call_process_model,
        tasks: [
          %Task{
            name: :call_process_task,
            type: :sub_process,
            sub_process: :service_subprocess_model,
            next: :service_task1
          },
          %Task{
            name: :service_task1,
            type: :service,
            function: fn data -> Map.put(data, :value, data.value + 1) end,
            next: :service_task2
          },
          %Task{
            name: :service_task2,
            type: :service,
            function: fn data -> Map.put(data, :value, data.value + 1) end,
            next: :service_task3
          },
          %Task{
            name: :service_task3,
            type: :service,
            function: fn data -> Map.put(data, :value, data.value + 1) end,
            next: nil
          }
        ],
        initial_task: :call_process_task
      },
      %ProcessModel{
        name: :service_subprocess_model,
        tasks: [
          %Task{
            name: :service_task1,
            type: :service,
            function: fn data -> Map.put(data, :value, data.value + 1) end,
            next: :service_task2
          },
          %Task{
            name: :service_task2,
            type: :service,
            function: fn data -> Map.put(data, :value, data.value + 1) end,
            next: :service_task3
          },
          %Task{
            name: :service_task3,
            type: :service,
            function: fn data -> Map.put(data, :value, data.value + 1) end,
            next: nil
          }
        ],
        initial_task: :service_task1
      }
    ]
  end

  def get_testing_process_models do
    [
      %ProcessModel{
        name: :simple_call_process_model,
        tasks: [
          %Task{
            name: :call_process_task,
            type: :sub_process,
            sub_process: :one_user_task_process,
            next: nil
          }
        ],
        initial_task: :call_process_task
      },
      %ProcessModel{
        name: :simple_call_service_process_model,
        tasks: [
          %Task{
            name: :call_process_task,
            type: :sub_process,
            sub_process: :service_subprocess_model,
            next: nil
          }
        ],
        initial_task: :call_process_task
      },
      %ProcessModel{
        name: :one_user_task_process,
        tasks: [
          %Task{
            name: :user_task,
            type: :user,
            assigned_groups: ["admin"],
            next: nil
          }
        ],
        initial_task: :user_task
      },
      %ProcessModel{
        name: :service_subprocess_model,
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
            name: :user_task,
            type: :user,
            assigned_groups: ["admin"],
            next: nil
          }
        ],
        initial_task: :user_task
      },
      %ProcessModel{
        name: :two_user_tasks_then_service,
        tasks: [
          %Task{
            name: :user_task_1,
            type: :user,
            assigned_groups: ["admin"],
            next: :user_task_2
          },
          %Task{
            name: :user_task_2,
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
