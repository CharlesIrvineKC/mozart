defmodule Mozart.TestModels do
  alias Mozart.Task.Service
  alias Mozart.Task.Receive
  alias Mozart.Task.Timer
  alias Mozart.Task.Parallel
  alias Mozart.Task.Subprocess
  alias Mozart.Task.Join
  alias Mozart.Task.User
  alias Mozart.Task.Choice
  alias Mozart.Task.Send
  alias Mozart.Task.Decision
  alias Mozart.Data.ProcessModel
  alias Mozart.Services.RestService

  def one_decision_task do
    [
    %ProcessModel{
      name: :process_with_single_decision_task,
      tasks: [
        %Decision{
          name: :decision_task,
          tablex: Tablex.new("""
          F  value  || color
          1  >90    || red
          2  80..90 || orange
          3  20..79 || green
          4  <20    || blue
          """),
          next: :identity_season
        },
        %Service{
          name: :identity_season,
          function: fn data ->
            cond do
              data.color == "green" -> Map.merge(data, %{season: "spring"})
              data.color == "orange" -> Map.merge(data, %{season: "fall"})
            end
          end
        },
      ],
      initial_task: :decision_task
    }
  ]
  end

  def send_task_to_receive_task do
    [
      %ProcessModel{
        name: :process_with_receive_task,
        tasks: [
          %Receive{
            name: :receive_task,
            message_selector: fn msg ->
              case msg do
                :message -> %{message: true}
                _ -> false
              end
            end
          }
        ],
        initial_task: :receive_task
      },
      %ProcessModel{
        name: :process_with_single_send_task,
        tasks: [
          %Send{
            name: :send_task,
            message: :message
          },
        ],
        initial_task: :send_task
      }
    ]
  end

  def single_send_event_task do
    [
      %ProcessModel{
        name: :process_with_single_send_evet_task,
        tasks: [
          %Send{
            name: :send_task,
            message: :foobar
          },
        ],
        initial_task: :send_task
      }
    ]
  end

  def single_service_task do
    [
      %ProcessModel{
        name: :process_with_single_service_task,
        tasks: [
          %Service{
            name: :service_task,
            function: fn data -> Map.merge(data, %{single_service: true}) end
          },
        ],
        initial_task: :service_task
      }
    ]
  end

  def call_process_receive_event_task do
    [
      %ProcessModel{
        name: :process_with_receive_event_task,
        tasks: [
          %Receive{
            name: :receive_task,
            message_selector: fn msg ->
              case msg do
                {a, b} -> %{value: a + b}
                _ -> false
              end
            end
          }
        ],
        initial_task: :receive_task
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
            timer_duration: 1000,
            next: :wait_3_seconds
          },
          %Timer{
            name: :wait_3_seconds,
            timer_duration: 3000
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
            function: fn data -> Map.merge(data, %{cat_facts: RestService.get_cat_facts()}) end
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
            multi_next: [:foo, :bar]
          },
          %Service{
            name: :foo,
            function: fn data -> Map.merge(data, %{foo: :foo}) end,
            next: :join_task
          },
          %Service{
            name: :bar,
            function: fn data -> Map.merge(data, %{bar: :bar}) end,
            next: :foo_bar
          },
          %Service{
            name: :foo_bar,
            function: fn data -> Map.merge(data, %{foo_bar: :foo_bar}) end,
            next: :join_task
          },
          %Join{
            name: :join_task,
            inputs: [:foo, :foo_bar],
            next: :final_service
          },
          %Service{
            name: :final_service,
            function: fn data -> Map.merge(data, %{final: :final}) end
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
          %Subprocess{
            name: :call_process_task,
            sub_process: :service_subprocess_model,
            next: :service_task1
          },
          %Service{
            name: :service_task1,
            function: fn data -> Map.put(data, :value, data.value + 1) end,
            next: :service_task2
          },
          %Service{
            name: :service_task2,
            function: fn data -> Map.put(data, :value, data.value + 1) end,
            next: :service_task3
          },
          %Service{
            name: :service_task3,
            function: fn data -> Map.put(data, :value, data.value + 1) end
          }
        ],
        initial_task: :call_process_task
      },
      %ProcessModel{
        name: :service_subprocess_model,
        tasks: [
          %Service{
            name: :service_task1,
            function: fn data -> Map.put(data, :value, data.value + 1) end,
            next: :service_task2
          },
          %Service{
            name: :service_task2,
            function: fn data -> Map.put(data, :value, data.value + 1) end,
            next: :service_task3
          },
          %Service{
            name: :service_task3,
            function: fn data -> Map.put(data, :value, data.value + 1) end
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
          %Subprocess{
            name: :call_process_task,
            sub_process: :one_user_task_process
          }
        ],
        initial_task: :call_process_task
      },
      %ProcessModel{
        name: :simple_call_service_process_model,
        tasks: [
          %Subprocess{
            name: :call_process_task,
            sub_process: :service_subprocess_model
          }
        ],
        initial_task: :call_process_task
      },
      %ProcessModel{
        name: :one_user_task_process,
        tasks: [
          %User{
            name: :user_task,
            assigned_groups: ["admin"]
          }
        ],
        initial_task: :user_task
      },
      %ProcessModel{
        name: :service_subprocess_model,
        tasks: [
          %Service{
            name: :service_task,
            function: fn data -> Map.merge(data, %{service: :service}) end
          }
        ],
        initial_task: :service_task
      },
      %ProcessModel{
        name: :choice_process_model,
        tasks: [
          %Choice{
            name: :choice_task,
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
            function: fn data -> Map.merge(data, %{foo: :foo}) end
          },
          %Service{
            name: :bar,
            function: fn data -> Map.merge(data, %{bar: :bar}) end
          }
        ],
        initial_task: :choice_task
      },
      %ProcessModel{
        name: :simple_process_model,
        tasks: [
          %Service{
            name: :foo,
            function: fn data -> Map.merge(data, %{bar: :bar}) end
          }
        ],
        initial_task: :foo
      },
      %ProcessModel{
        name: :user_task_process_model,
        tasks: [
          %User{
            name: :user_task,
            assigned_groups: ["admin"]
          }
        ],
        initial_task: :user_task
      },
      %ProcessModel{
        name: :two_user_tasks_then_service,
        tasks: [
          %User{
            name: :user_task_1,
            assigned_groups: ["admin"],
            next: :user_task_2
          },
          %User{
            name: :user_task_2,
            assigned_groups: ["admin"],
            next: :increment_by_one_task
          },
          %Service{
            name: :increment_by_one_task,
            function: fn map -> Map.put(map, :value, map.value + 1) end
          }
        ],
        initial_task: :user_task_1
      },
      %ProcessModel{
        name: :user_task_then_service,
        tasks: [
          %User{
            name: :user_task_1,
            assigned_groups: ["admin"],
            next: :increment_by_one_task
          },
          %Service{
            name: :increment_by_one_task,
            function: fn map -> Map.put(map, :value, map.value + 1) end
          }
        ],
        initial_task: :user_task_1
      },
      %ProcessModel{
        name: :service_then_user_task,
        tasks: [
          %Service{
            name: :increment_by_one_task,
            function: fn map -> Map.put(map, :value, map.value + 1) end,
            next: :user_task_1
          },
          %User{
            name: :user_task_1,
            assigned_groups: ["admin"]
          }
        ],
        initial_task: :increment_by_one_task
      },
      %ProcessModel{
        name: :increment_by_one_process,
        tasks: [
          %Service{
            name: :increment_by_one_task,
            function: fn map -> Map.put(map, :value, map.value + 1) end
          }
        ],
        initial_task: :increment_by_one_task
      },
      %ProcessModel{
        name: :increment_by_one_twice_process,
        tasks: [
          %Service{
            name: :increment_by_one_task,
            function: fn map -> Map.put(map, :value, map.value + 1) end,
            next: :increment_by_two_task
          },
          %Service{
            name: :increment_by_two_task,
            function: fn map -> Map.put(map, :value, map.value + 2) end
          }
        ],
        initial_task: :increment_by_one_task
      },
      %ProcessModel{
        name: :three_increment_by_one_process,
        tasks: [
          %Service{
            name: :increment_by_one_task,
            function: fn map -> Map.put(map, :value, map.value + 1) end,
            next: :increment_by_two_task
          },
          %Service{
            name: :increment_by_two_task,
            function: fn map -> Map.put(map, :value, map.value + 2) end,
            next: :increment_by_three_task
          },
          %Service{
            name: :increment_by_three_task,
            function: fn map -> Map.put(map, :value, map.value + 3) end
          }
        ],
        initial_task: :increment_by_one_task
      }
    ]
  end
end
