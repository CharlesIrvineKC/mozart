defmodule Mozart.Performance.TestUtils do
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
  alias Mozart.Performance.RestService

  ## Demo decision task

  def get_loan_models do
    [
      %ProcessModel{
        name: :loan_approval,
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
    PMS.load_process_models(get_loan_models())
    data = %{loan_args: [income: 3000]}

    {:ok, ppid, uid} = PE.start_process(:loan_approval, data)
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
    PMS.load_process_models(send_task_to_receive_task())
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
    PMS.load_process_models(single_service_task())
    data = %{value: 0}

    {:ok, ppid, uid} = PE.start_process(:process_with_single_service_task, data)
    PE.execute(ppid)
    Process.sleep(1000)

    completed_process = PS.get_completed_process(uid)
    IO.inspect(completed_process, label: "service process state")

    IO.puts("finished")
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
    PMS.load_process_models(call_timer_tasks())
    data = %{}

    {:ok, ppid, uid} = PE.start_process(:call_timer_task, data)
    PE.execute(ppid)
    Process.sleep(1000)

    completed_process = PS.get_completed_process(uid)
    IO.inspect(completed_process, label: "service process state")

    IO.puts("finished")
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
    PMS.load_process_models(parallel_process_with_join_models())
    data = %{value: 1}
    {:ok, ppid, uid} = PE.start_process(:parallel_process_model, data)
    PE.execute(ppid)
    Process.sleep(1000)

    completed_process = PS.get_completed_process(uid)
    IO.inspect(completed_process, label: "parallel process state")

    IO.puts("finished")
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
    PMS.load_process_models(subprocess_process_models())
    data = %{value: 1}

    {:ok, ppid, uid} = PE.start_process(:call_process_model, data)

    PE.execute(ppid)
    Process.sleep(1000)

    completed_process = PS.get_completed_process(uid)
    IO.inspect(completed_process, label: "subprocess process state")

    IO.puts("finished")
  end

  ## User task demo

  def user_task_process do
    [
      %ProcessModel{
        name: :user_task_process_model,
        tasks: [
          %User{
            name: :user_task,
            assigned_groups: ["admin"]
          }
        ],
        initial_task: :user_task
      }
    ]
  end

  # PMS.load_process_models(user_task_process())

  def run_user_task_process do
    data = %{value: 0}
    {:ok, ppid, uid} = PE.start_process(:user_task_process_model, data)
    PE.execute(ppid)
    Process.sleep(1000)

    [task_instance] = Map.values(PE.get_open_tasks(ppid))
    PE.complete_user_task_and_go(ppid, task_instance.uid, %{user_task_complete: true})
    Process.sleep(1000)

    completed_process = PS.get_completed_process(uid)
    IO.inspect(completed_process, label: "user task process state")

    IO.puts("finished")
  end

  ## Demo choice task

  def choice_process_model do
    [
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
      }
    ]
  end

  def run_choice_process_model do
    PMS.load_process_models(choice_process_model())
    data = %{value: 1}
    {:ok, ppid, uid} = PE.start_process(:choice_process_model, data)
    PE.execute(ppid)
    Process.sleep(1000)

    completed_process = PS.get_completed_process(uid)
    IO.inspect(completed_process, label: "choice task process state")

    IO.puts("finished")
  end

  def run_all do
    run_get_loan_models()
    run_send_task_to_receive_task()
    run_single_service_task()
    run_call_timer_tasks()
    run_parallel_process_model()
    run_subprocess_process()
    run_user_task_process()
    run_choice_process_model()
  end

  ## The following functions are ad hoc for investigating performance

  def clear_and_load() do
    PS.clear_state()
    PMS.clear_state()
    load_model(get_model())
  end

  def load_model(model) do
    PMS.load_process_model(model)
  end

  def get_model() do
    %ProcessModel{
      name: :process_with_single_service_task,
      tasks: [
        %Service{
          name: :service_task_1,
          function: &RestService.small_payload_service(&1),
          next: :service_task_2
        },
        %Service{
          name: :service_task_2,
          function: &RestService.small_payload_service(&1),
          next: :service_task_3
        },
        %Service{
          name: :service_task_3,
          function: &RestService.small_payload_service(&1),
          next: :service_task_4
        },
        %Service{
          name: :service_task_4,
          function: &RestService.small_payload_service(&1),
          next: :service_task_5
        },
        %Service{
          name: :service_task_5,
          function: &RestService.small_payload_service(&1),
          next: :service_task_6
        },
        %Service{
          name: :service_task_6,
          function: &RestService.small_payload_service(&1),
          next: :service_task_7
        },
        %Service{
          name: :service_task_7,
          function: &RestService.small_payload_service(&1),
          next: :service_task_8
        },
        %Service{
          name: :service_task_8,
          function: &RestService.small_payload_service(&1),
          next: :service_task_9
        },
        %Service{
          name: :service_task_9,
          function: &RestService.small_payload_service(&1),
          next: :service_task_10
        },
        %Service{
          name: :service_task_10,
          function: &RestService.small_payload_service(&1),
        },
      ],
      initial_task: :service_task_1
    }
  end

  def get_timer_model do
    %ProcessModel{
      name: :call_timer_task,
      tasks: [
        %Timer{
          name: :wait_1_seconds,
          timer_duration: 10,
          next: :wait_3_seconds
        },
        %Timer{
          name: :wait_3_seconds,
          timer_duration: 30
        }
      ],
      initial_task: :wait_1_seconds
    }
  end

  def run_process_n_times(data, model_name, n) do
    Logger.configure(level: :emergency)

    function = fn data, model_name ->
      {:ok, ppid, _uid} = PE.start_process(model_name, data)
      PE.execute(ppid)
    end

    1..n |> Enum.each(fn _v -> function.(data, model_name) end)
  end
end
