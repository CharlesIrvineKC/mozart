defmodule Mozart.ProcessEngineTest do
  use ExUnit.Case

  alias Mozart.ProcessModels.TestModels
  alias Mozart.ProcessEngine, as: PE
  alias Mozart.ProcessService, as: PS
  alias Mozart.Task.User
  alias Mozart.Task.Subprocess
  alias Mozart.Task.Service
  alias Mozart.Task.Receive
  alias Mozart.Task.Repeat
  alias Mozart.Task.Prototype
  alias Mozart.Event.TaskExit
  alias Mozart.Data.ProcessModel
  alias Phoenix.PubSub

  defp get_repeat_process do
    %ProcessModel{
      name: :repeat_process_model,
      initial_task: :first_user_task,
      tasks: [
        %User{
          name: :first_user_task,
          assigned_groups: ["admin"],
          next: :repeat_task
        },
        %Repeat{
          name: :repeat_task,
          first: :first_prototype_task,
          last: :last_user_task,
          condition: fn data -> data.continue end,
          next: :prototype_task_after_repeat
        },
        %Prototype{
          name: :first_prototype_task,
          next: :last_user_task
        },
        %User{
          name: :last_user_task,
        },
        %Prototype{
          name: :prototype_task_after_repeat
        }
      ]
    }
  end

  test "repeat task" do
    PS.clear_state()
    PS.load_process_model(get_repeat_process())
    data = %{continue: false}

    {:ok, ppid, _uid, _business_key} = PE.start_process(:repeat_process_model, data)
    PE.execute(ppid)
    Process.sleep(100)

    user_task = hd(PS.get_user_tasks())
    PS.complete_user_task(user_task.uid, %{continue: true})
    Process.sleep(100)

    user_task = hd(PS.get_user_tasks())
    PS.complete_user_task(user_task.uid, %{continue: true})
    Process.sleep(100)

    user_task = hd(PS.get_user_tasks())
    PS.complete_user_task(user_task.uid, %{continue: false})
  end

  defp get_event_on_user_task do
    %ProcessModel{
      name: :event_on_user_task_process,
      tasks: [
        %User{
          name: :user_task,
          assigned_groups: ["admin"]
        }
      ],
      events: [
        %TaskExit{
          name: :exit_user_task,
          exit_task: :user_task,
          selector: fn msg ->
            case msg do
              :exit_user_task -> true
              _ -> nil
            end
          end
        }
      ],
      initial_task: :user_task
    }
  end

  test "exit event on user task" do
    PS.clear_state()
    PS.load_process_model(get_event_on_user_task())
    data = %{}

    {:ok, ppid, _uid, _business_key} = PE.start_process(:event_on_user_task_process, data)
    PE.execute(ppid)
    Process.sleep(100)

    PubSub.broadcast(:pubsub, "pe_topic", {:event, :exit_user_task})
  end

  test "call json service" do
    PS.clear_state()
    PS.load_process_models(TestModels.call_exteral_services())
    data = %{}

    {:ok, ppid, uid, _business_key} = PE.start_process(:call_external_service, data)
    catch_exit(PE.execute_and_wait(ppid))

    completed_process = PS.get_completed_process(uid)

    assert completed_process.data == %{
             todo_data: %{
               "completed" => false,
               "id" => 1,
               "title" => "delectus aut autem",
               "userId" => 1
             }
           }

    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 1
    [task] = completed_process.completed_tasks
    assert task.duration != nil
  end

  test "process with single send event task" do
    PS.clear_state()
    PS.load_process_models(TestModels.single_send_event_task())
    data = %{value: 0}

    {:ok, ppid, uid, _business_key} = PE.start_process(:process_with_single_send_evet_task, data)
    catch_exit(PE.execute_and_wait(ppid))

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{value: 0}
    assert completed_process.complete == true
  end

  test "process with receive event and another with a send event" do
    PS.clear_state()
    PS.load_process_models(TestModels.send_task_to_receive_task())
    data = %{}

    {:ok, r_ppid, r_uid, _business_key} = PE.start_process(:process_with_receive_task, data)
    PE.execute_and_wait(r_ppid)

    {:ok, s_ppid, s_uid, _business_key} = PE.start_process(:process_with_single_send_task, data)
    catch_exit(PE.execute_and_wait(s_ppid))

    Process.sleep(1000)

    receive_process = PS.get_completed_process(r_uid)
    send_process = PS.get_completed_process(s_uid)

    assert receive_process.complete == true
    assert send_process.complete == true

    receive_tasks = receive_process.completed_tasks
    send_tasks = send_process.completed_tasks

    assert length(receive_tasks) == 1
    assert length(send_tasks) == 1

    assert Enum.all?(receive_tasks, fn t -> t.duration end) == true
    assert Enum.all?(send_tasks, fn t -> t.duration end) == true
  end

  def single_service_task do
    %ProcessModel{
      name: :process_with_single_service_task,
      tasks: [
        %Service{
          name: :service_task,
          inputs: [:x],
          function: fn data -> Map.put(data, :x, data.x + 1) end
        }
      ],
      initial_task: :service_task
    }
  end

  test "process with a single service task" do
    PS.clear_state()
    PS.load_process_model(single_service_task())
    data = %{x: 0, y: 0}

    {:ok, ppid, uid, _business_key} = PE.start_process(:process_with_single_service_task, data)
    catch_exit(PE.execute_and_wait(ppid))

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{x: 1, y: 0}
    assert completed_process.complete == true

    assert Enum.all?(completed_process.completed_tasks, fn t -> t.duration end) == true
  end

  def call_process_receive_event_task do
    %ProcessModel{
      name: :process_with_receive_event_task,
      tasks: [
        %Receive{
          name: :receive_task,
          selector: fn msg ->
            case msg do
              {:get_sum, a, b} -> %{sum: a + b}
              _ -> nil
            end
          end
        }
      ],
      initial_task: :receive_task
    }
  end

  test "receive non matching event task" do
    PS.clear_state()
    PS.load_process_model(call_process_receive_event_task())
    data = %{}

    {:ok, ppid, uid, _business_key} = PE.start_process(:process_with_receive_event_task, data)
    PE.execute_and_wait(ppid)

    PubSub.broadcast(:pubsub, "pe_topic", {:message, {:get_product, 2, 2}})
    Process.sleep(10)

    assert PS.get_completed_process(uid) == nil
  end

  test "call process with a receive event task" do
    PS.clear_state()
    PS.load_process_model(call_process_receive_event_task())
    data = %{}

    {:ok, ppid, uid, _business_key} = PE.start_process(:process_with_receive_event_task, data)
    PE.execute_and_wait(ppid)

    PubSub.broadcast(:pubsub, "pe_topic", {:message, {:get_sum, 2, 2}})
    Process.sleep(10)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{sum: 4}
    assert completed_process.complete == true
  end

  test "call process with one timer task" do
    PS.clear_state()
    PS.load_process_models(TestModels.call_timer_tasks())
    data = %{}

    {:ok, ppid, uid, _business_key} = PE.start_process(:call_timer_task, data)
    PE.execute_and_wait(ppid)

    Process.monitor(ppid)
    assert_receive(_msg, 500)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 2
  end

  # test "call an external service" do
  # PS.clear_state()
  #   PS.load_process_models(TestModels.call_exteral_services())
  #   data = %{}

  #   {:ok, ppid, uid, _business_key} = PE.start_process(:call_external_services, data)
  #   PE.execute(ppid)
  #   Process.sleep(2000)
  #   assert PS.get_completed_process(uid) != nil
  # end

  test "complex process model" do
    PS.clear_state()
    PS.load_process_models(TestModels.get_complex_process_models())
    data = %{value: 1}

    {:ok, ppid, uid, _business_key} = PE.start_process(:call_process_model, data)
    PE.execute(ppid)

    Process.sleep(100)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{value: 7}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 4
  end

  test "start server and get id" do
    PS.clear_state()
    PS.load_process_models(TestModels.get_testing_process_models())
    data = %{foo: "foo"}

    {:ok, ppid, uid, _business_key} = PE.start_process(:simple_process_model, data)
    catch_exit(PE.execute_and_wait(ppid))

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{foo: "foo", bar: :bar}
    assert completed_process.complete == true
  end

  test "execute process with subprocess with a user subprocess" do
    PS.clear_state()
    PS.load_process_models(TestModels.get_testing_process_models())
    data = %{value: 1}
    {:ok, ppid, _uid, _business_key} = PE.start_process(:simple_call_process_model, data)
    PE.execute(ppid)
  end

  def get_subprocess_models do
    [
      %ProcessModel{
        name: :call_process_model,
        tasks: [
          %Subprocess{
            name: :call_process_task,
            model: :service_subprocess_model,
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

  test "execute process with service subprocess" do
    PS.clear_state()
    PS.load_process_models(get_subprocess_models())
    data = %{value: 1}
    {:ok, ppid, uid, _business_key} = PE.start_process(:call_process_model, data)
    PE.execute(ppid)

    Process.sleep(500)

    completed_process = PS.get_completed_process(uid)
    assert length(completed_process.completed_tasks) == 2
    assert completed_process.data == %{value: 2, subprocess_data: "subprocess data"}
    assert completed_process.complete == true
    assert length(PS.get_completed_processes()) == 2
  end

  test "execute process with parallel task and join" do
    PS.clear_state()
    PS.load_process_models(TestModels.get_parallel_process_models())
    data = %{value: 1}
    {:ok, ppid, uid, _business_key} = PE.start_process(:parallel_process_model, data)
    catch_exit(PE.execute_and_wait(ppid))

    completed_process = PS.get_completed_process(uid)

    assert completed_process.data == %{
             value: 1,
             foo: :foo,
             bar: :bar,
             foo_bar: :foo_bar,
             final: :final
           }

    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 6
  end

  test "execute process with case returning :foo" do
    PS.clear_state()
    PS.load_process_models(TestModels.get_testing_process_models())
    data = %{value: 1}
    {:ok, ppid, uid, _business_key} = PE.start_process(:case_process_model, data)
    catch_exit(PE.execute_and_wait(ppid))

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{value: 1, foo: :foo}
    assert completed_process.complete == true
    assert length(completed_process.completed_tasks) == 2
  end

  test "execute process with case returning :bar" do
    PS.clear_state()
    PS.load_process_models(TestModels.get_testing_process_models())
    data = %{value: 11}
    {:ok, ppid, uid, _business_key} = PE.start_process(:case_process_model, data)
    catch_exit(PE.execute_and_wait(ppid))

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{value: 11, bar: :bar}
    assert completed_process.complete == true
  end

  test "one user task" do
    PS.clear_state()
    PS.load_process_models(TestModels.get_testing_process_models())
    data = %{value: 0}
    {:ok, ppid, _uid, _business_key} = PE.start_process(:user_task_process_model, data)
    PE.execute_and_wait(ppid)

    assert PE.get_data(ppid) == %{value: 0}
    open_tasks = Map.values(PE.get_open_tasks(ppid))
    assert Enum.map(open_tasks, fn t_i -> t_i.name end) == [:user_task]
    assert PE.is_complete(ppid) == false
  end

  @user_process_models [
    %ProcessModel{
      name: :user_task_process_model,
      tasks: [
        %User{
          name: :user_task,
          inputs: [:x, :y],
          assigned_groups: ["admin"]
        }
      ],
      initial_task: :user_task
    }
  ]

  test "complete one user task" do
    PS.clear_state()
    PS.load_process_models(@user_process_models)
    data = %{x: 1, y: 1, z: 1}
    {:ok, ppid, uid, _business_key} = PE.start_process(:user_task_process_model, data)
    PE.execute_and_wait(ppid)

    assert PE.get_data(ppid) == %{x: 1, y: 1, z: 1}

    [user_task] = Map.values(PE.get_open_tasks(ppid))

    ps_user_task = PS.get_user_task(user_task.uid)
    {x, y} = {ps_user_task.data.x, ps_user_task.data.y}
    catch_exit(PE.complete_user_task(ppid, user_task.uid, %{sum: x + y}))
    Process.sleep(10)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{sum: 2, x: 1, y: 1, z: 1}
    assert completed_process.complete == true
  end

  test "complete one user task then sevice task" do
    PS.clear_state()
    PS.load_process_models(TestModels.get_testing_process_models())
    data = %{value: 0}
    {:ok, ppid, uid, _business_key} = PE.start_process(:user_task_then_service, data)
    PE.execute_and_wait(ppid)

    # Process.sleep(10)
    assert PE.get_data(ppid) == %{value: 0}
    task_names = Enum.map(Map.values(PE.get_open_tasks(ppid)), fn t -> t.name end)
    assert task_names == [:user_task_1]
    [task_instance] = Map.values(PE.get_open_tasks(ppid))

    catch_exit(PE.complete_user_task(ppid, task_instance.uid, %{foo: :foo, bar: :bar}))

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{value: 1, foo: :foo, bar: :bar}
    assert completed_process.complete == true
  end

  test "complete one servuce task then user task" do
    PS.clear_state()
    PS.load_process_models(TestModels.get_testing_process_models())
    data = %{value: 0}
    {:ok, ppid, uid, _business_key} = PE.start_process(:service_then_user_task, data)
    PE.execute_and_wait(ppid)
    assert PE.get_data(ppid) == %{value: 1}

    task_uids = Map.keys(PE.get_open_tasks(ppid))
    [task_uid] = task_uids
    catch_exit(PE.complete_user_task(ppid, task_uid, %{foo: :foo, bar: :bar}))

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{value: 1, foo: :foo, bar: :bar}
    assert completed_process.complete == true
  end

  test "set and get process state model" do
    PS.clear_state()
    PS.load_process_models(TestModels.get_testing_process_models())
    data = %{foo: :foo}
    {:ok, ppid, uid, _business_key} = PE.start_process(:simple_process_model, data)
    catch_exit(PE.execute_and_wait(ppid))

    completed_process = PS.get_completed_process(uid)
    assert completed_process.complete == true
    assert completed_process.model_name == :simple_process_model
  end

  test "set and get data" do
    PS.clear_state()
    PS.load_process_models(TestModels.get_testing_process_models())
    data = %{value: 1}
    {:ok, ppid, uid, _business_key} = PE.start_process(:simple_process_model, data)
    catch_exit(PE.execute_and_wait(ppid))

    completed_process = PS.get_completed_process(uid)
    assert completed_process.complete == true
    assert completed_process.data == %{value: 1, bar: :bar}
  end

  test "get process model open tasks" do
    PS.clear_state()
    PS.load_process_models(TestModels.get_testing_process_models())
    data = %{value: 1}
    {:ok, ppid, uid, _business_key} = PE.start_process(:simple_process_model, data)
    catch_exit(PE.execute_and_wait(ppid))

    completed_process = PS.get_completed_process(uid)
    assert completed_process.complete == true
    assert completed_process.data == %{value: 1, bar: :bar}
  end

  test "complete increment by one task" do
    PS.clear_state()
    PS.load_process_models(TestModels.get_testing_process_models())
    data = %{value: 0}
    {:ok, ppid, uid, _business_key} = PE.start_process(:increment_by_one_process, data)
    catch_exit(PE.execute_and_wait(ppid))

    completed_process = PS.get_completed_process(uid)
    assert completed_process.complete == true
    assert completed_process.data == %{value: 1}
  end

  test "correcting bad data and re-executing" do
    PS.clear_state()
    # Will cause a process restart due to adding 1 to "foobar"
    PS.load_process_models(TestModels.get_testing_process_models())
    data = %{value: "foobar"}
    {:ok, ppid, uid, _business_key} = PE.start_process(:increment_by_one_process, data)
    PE.execute(ppid)

    Process.monitor(ppid)
    assert_receive({:DOWN, _ref, :process, _object, _reason})
    Process.sleep(100)

    # Process will have been restarted. Get new pid.
    new_pid = PS.get_process_ppid(uid)
    # Correct data
    PE.set_data(new_pid, %{value: 1})
    PE.execute(new_pid)
    Process.sleep(100)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.complete == true
    assert completed_process.data == %{value: 2}
  end

  test "two increment tasks in a row" do
    PS.clear_state()
    PS.load_process_models(TestModels.get_testing_process_models())
    data = %{value: 0}

    {:ok, ppid, uid, _business_key} = PE.start_process(:increment_by_one_twice_process, data)

    catch_exit(PE.execute_and_wait(ppid))

    completed_process = PS.get_completed_process(uid)
    assert completed_process.complete == true
    assert completed_process.data == %{value: 3}
  end

  test "Three increment tasks in a row" do
    PS.load_process_models(TestModels.get_testing_process_models())
    data = %{value: 0}
    {:ok, ppid, uid, _business_key} = PE.start_process(:three_increment_by_one_process, data)
    catch_exit(PE.execute_and_wait(ppid))

    completed_process = PS.get_completed_process(uid)
    assert completed_process.complete == true
    assert completed_process.data == %{value: 6}
    assert completed_process.open_tasks == %{}
  end
end
