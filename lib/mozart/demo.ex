defmodule Mozart.Demo do
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

  alias Mozart.ProcessEngine, as: PE
  alias Mozart.ProcessModelService, as: PMS
  alias Mozart.ProcessService, as: PS

  ## Demo decision task

  def get_loan_models do
    [
      %ProcessModel{
        name: :load_approval,
        tasks: [
          %Decision{
            name: :loan_decision,
            decision_args: :loan_args,
            tablex:
              Tablex.new("""
              F     income      || status
              1     > 50000     || approved
              2     <= 49999    || declined
              """)
          }
        ],
        initial_task: :loan_decision
      }
    ]
  end

  def run_get_loan_models do
    PMS.clear_then_load_process_models(get_loan_models())
    data = %{loan_args: [income: 3000]}

    {:ok, ppid, uid} = PE.start_process(:load_approval, data)
    PE.execute(ppid)

    Process.sleep(1000)

    completed_process = PS.get_completed_process(uid)
    IO.inspect(completed_process)

    IO.puts("finished")
  end

  ## Demo send and receive tasks

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
          }
        ],
        initial_task: :send_task
      }
    ]
  end

  def run_send_task_to_receive_task do
    PMS.clear_then_load_process_models(send_task_to_receive_task())
    data = %{}

    {:ok, r_ppid, r_uid} = PE.start_process(:process_with_receive_task, data)
    PE.execute(r_ppid)
    Process.sleep(1000)

    {:ok, s_ppid, s_uid} = PE.start_process(:process_with_single_send_task, data)
    PE.execute(s_ppid)
    Process.sleep(1000)

    completed_process = PS.get_completed_process(r_uid)
    IO.inspect(completed_process, label: "receive process state")

    completed_process = PS.get_completed_process(s_uid)
    IO.inspect(completed_process, label: "send process state")

    IO.puts("finished")
  end

  ## Demo service task

  def single_service_task do
    [
      %ProcessModel{
        name: :process_with_single_service_task,
        tasks: [
          %Service{
            name: :service_task,
            function: fn data -> Map.merge(data, %{single_service: true}) end
          }
        ],
        initial_task: :service_task
      }
    ]
  end

  def run_single_service_task do
    PMS.clear_then_load_process_models(single_service_task())
    data = %{value: 0}

    {:ok, ppid, uid} = PE.start_process(:process_with_single_service_task, data)
    PE.execute(ppid)
    Process.sleep(1000)

    completed_process = PS.get_completed_process(uid)
    IO.inspect(completed_process, label: "service process state")

    IO.puts "finished"
  end

  ## Demo timer task

  def call_timer_tasks do
    [
      %ProcessModel{
        name: :call_timer_task,
        tasks: [
          %Timer{
            name: :wait_1_seconds,
            timer_duration: 100,
            next: :wait_3_seconds
          },
          %Timer{
            name: :wait_3_seconds,
            timer_duration: 300
          }
        ],
        initial_task: :wait_1_seconds
      }
    ]
  end

  def run_call_timer_tasks do
    PMS.clear_then_load_process_models(call_timer_tasks())
    data = %{}

    {:ok, ppid, uid} = PE.start_process(:call_timer_task, data)
    PE.execute(ppid)
    Process.sleep(1000)

    completed_process = PS.get_completed_process(uid)
    IO.inspect(completed_process, label: "service process state")

    IO.puts "finished"
  end

  ## Demo parallel tasks

  def parallel_process_with_join_models do
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

  def run_parallel_process_model do
    PMS.clear_then_load_process_models(parallel_process_with_join_models())
    data = %{value: 1}
    {:ok, ppid, uid} = PE.start_process(:parallel_process_model, data)
    PE.execute(ppid)
    Process.sleep(1000)

    completed_process = PS.get_completed_process(uid)
    IO.inspect(completed_process, label: "parallel process state")

    IO.puts "finished"
  end

  ## Demo subprocess model

  def subprocess_process_models do
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
            function: fn data -> Map.put(data, :value, data.value + 1) end
          }
        ],
        initial_task: :call_process_task
      },
      %ProcessModel{
        name: :service_subprocess_model,
        tasks: [
          %Service{
            name: :service_task,
            function: fn data -> Map.put(data, :subprocess_data, "subprocess data") end
          }
        ],
        initial_task: :service_task
      }
    ]
  end

 def run_subprocess_process do
  PMS.clear_then_load_process_models(subprocess_process_models())
  data = %{value: 1}

  {:ok, ppid, uid} = PE.start_process(:call_process_model, data)

  PE.execute(ppid)
  Process.sleep(1000)

  completed_process = PS.get_completed_process(uid)
  IO.inspect(completed_process, label: "subprocess process state")

  IO.puts "finished"
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
