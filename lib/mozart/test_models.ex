defmodule Mozart.TestModels do
  alias Mozart.Task.Task
  alias Mozart.Task.Service
  alias Mozart.Task.Subscribe
  alias Mozart.Task.Timer
  alias Mozart.Task.Parallel
  alias Mozart.Data.ProcessModel
  alias Mozart.Services.RestService

  def single_service_task do
    [
      %ProcessModel{
        name: :process_with_single_service_task,
        tasks: [
          %Service{
            name: :service_task,
            type: :service,
            function: fn data -> Map.merge(data, %{single_service: true}) end,
            next: nil
          },
        ],
        initial_task: :service_task
      }
    ]
  end

  def call_process_subscribe_task do
    [
      %ProcessModel{
        name: :process_with_subscribe_task,
        tasks: [
          %Subscribe{
            name: :subscribe_task,
            type: :subscribe,
            message_selector: fn msg ->
              case msg do
                {a, b} -> %{value: a + b}
                _ -> false
              end
            end,
            next: nil
          }
        ],
        initial_task: :subscribe_task
      }
    ]
  end

  def call_timer_tasks do
    [
      %ProcessModel{
        name: :call_timer_task,
        tasks: [
          %Timer{
            name: :wait_1_seconds,
            type: :timer,
            timer_duration: 1000,
            next: :wait_3_seconds
          },
          %Timer{
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
          %Service{
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
          %Parallel{
            name: :parallel_task,
            type: :parallel,
            multi_next: [:foo, :bar]
          },
          %Service{
            name: :foo,
            type: :service,
            function: fn data -> Map.merge(data, %{foo: :foo}) end,
            next: :join_task
          },
          %Service{
            name: :bar,
            type: :service,
            function: fn data -> Map.merge(data, %{bar: :bar}) end,
            next: :foo_bar
          },
          %Service{
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
          %Service{
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
          %Service{
            name: :service_task1,
            type: :service,
            function: fn data -> Map.put(data, :value, data.value + 1) end,
            next: :service_task2
          },
          %Service{
            name: :service_task2,
            type: :service,
            function: fn data -> Map.put(data, :value, data.value + 1) end,
            next: :service_task3
          },
          %Service{
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
          %Service{
            name: :service_task1,
            type: :service,
            function: fn data -> Map.put(data, :value, data.value + 1) end,
            next: :service_task2
          },
          %Service{
            name: :service_task2,
            type: :service,
            function: fn data -> Map.put(data, :value, data.value + 1) end,
            next: :service_task3
          },
          %Service{
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
          %Service{
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
          %Service{
            name: :foo,
            type: :service,
            function: fn data -> Map.merge(data, %{foo: :foo}) end,
            next: nil
          },
          %Service{
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
          %Service{
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
          %Service{
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
          %Service{
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
          %Service{
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
          %Service{
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
          %Service{
            name: :increment_by_one_task,
            type: :service,
            function: fn map -> Map.put(map, :value, map.value + 1) end,
            next: :increment_by_two_task
          },
          %Service{
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
          %Service{
            name: :increment_by_one_task,
            type: :service,
            function: fn map -> Map.put(map, :value, map.value + 1) end,
            next: :increment_by_two_task
          },
          %Service{
            name: :increment_by_two_task,
            type: :service,
            function: fn map -> Map.put(map, :value, map.value + 2) end,
            next: :increment_by_three_task
          },
          %Service{
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
