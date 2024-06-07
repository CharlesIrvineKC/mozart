defmodule Mozart.ProcessServiceTest do
  use ExUnit.Case

  alias Mozart.UserService, as: US
  alias Mozart.ProcessService, as: PS
  alias Mozart.ProcessEngine, as: PE
  alias Mozart.ProcessModels.TestModels

  alias Mozart.Data.MozartUser
  alias Mozart.Data.ProcessModel

  alias Mozart.Task.User
  alias Mozart.Task.Choice
  alias Mozart.Task.Subprocess

  alias Mozart.Event.TaskExit

  setup do
    PS.clear_user_tasks()
  end

  setup_all do
    US.insert_user(%MozartUser{name: "crirvine", groups: ["admin"]})
  end

  def get_home_loan_process do
    %ProcessModel{
      name: :home_loan_process,
      tasks: [
        %User{
          name: :perform_pre_approval,
          input_fields: [:credit_score, :income, :debt_amount],
          assigned_groups: ["credit"],
          next: :route_on_pre_approval_completion
        },
        %Choice{
          name: :route_on_pre_approval_completion,
          choices: [
            %{
              expression: fn data -> data.pre_approval == true end,
              next: :receive_mortgage_application
            },
            %{
              expression: fn data -> data.pre_approval == false end,
              next: :communicate_loan_denied
            }
          ]
        },
        %User{
          name: :receive_mortgage_application,
          input_fields: [:credit_score, :income, :debt_amount],
          assigned_groups: ["credit"],
          next: :process_loan
        },
        %User{
          name: :process_loan,
          input_fields: [:purchase_price, :credit_score, :income, :debt_amount],
          assigned_groups: ["credit"],
          next: :process_loan_outcome
        },
        %Choice{
          name: :process_loan_outcome,
          choices: [
            %{
              expression: fn data -> data.loan_verified == true end,
              next: :perform_underwriting
            },
            %{
              expression: fn data -> data.loan_verified == false end,
              next: :communicate_loan_denied
            }
          ]
        },
        %User{
          name: :perform_underwriting,
          input_fields: [:purchase_price, :credit_score, :income, :debt_amount, :loan_verified],
          assigned_groups: ["underwriting"],
          next: :route_from_underwriting
        },
        %Choice{
          name: :route_from_underwriting,
          choices: [
            %{
              expression: fn data -> data.loan_approved == true end,
              next: :communicate_approval
            },
            %{
              expression: fn data -> data.loan_approved == false end,
              next: :communicate_loan_denied

            }
          ]
        },
        %User{
          name: :communicate_approval,
          input_fields: [:loan_approved],
          assigned_groups: ["credit"]
        },
        %User{
          name: :communicate_loan_denied,
          input_fields: [:loan_approved],
          assigned_groups: ["credit"]
        },
      ],
      initial_task: :perform_pre_approval
      }
  end

  test "run loan approval" do
    PS.clear_state()
    PS.load_process_model(get_home_loan_process())
    data = %{credit_score: 700, income: 100_000, debt_amount: 20_000}
    {:ok, ppid, uid} = PE.start_process(:home_loan_process, data)
    PE.execute(ppid)
    Process.sleep(100)

    ## complete pre approval
    [user_task] = PS.get_user_tasks_for_groups(["credit"])
    PS.complete_user_task(ppid, user_task.uid, %{pre_approval: true})
    Process.sleep(100)

    ## complete receive mortgage application
    [user_task] = PS.get_user_tasks_for_groups(["credit"])
    PS.complete_user_task(ppid, user_task.uid, %{purchase_price: 500_000})
    Process.sleep(100)

    ## process loan
    [user_task] = PS.get_user_tasks_for_groups(["credit"])
    PS.complete_user_task(ppid, user_task.uid, %{loan_verified: true})
    Process.sleep(100)

    ## perform underwriting
    [user_task] = PS.get_user_tasks_for_groups(["underwriting"])
    PS.complete_user_task(ppid, user_task.uid, %{loan_approved: true})
    Process.sleep(100)

    ## communicate approval
    [user_task] = PS.get_user_tasks_for_groups(["credit"])
    PS.complete_user_task(ppid, user_task.uid, %{loan_approved: true})
    Process.sleep(100)

    completed_process = PS.get_completed_process(uid)
    completed_tasks = completed_process.completed_tasks
    assert Enum.all?(completed_tasks, fn t -> t.duration end) == true
  end

  test "get user tasks for person" do
    PS.clear_user_tasks()
    tasks = PS.get_user_tasks_for_user("crirvine")
    assert tasks == []
  end

  defp get_exit_event_on_sub_process do
    [
      %ProcessModel{
        name: :simple_call_process_model,
        tasks: [
          %Subprocess{
            name: :call_process_task,
            sub_process_model_name: :sub_process_with_one_user_task
          }
        ],
        events: [
          %TaskExit{
            name: :exit_sub_process,
            exit_task: :call_process_task,
            message_selector: fn msg ->
              case msg do
                :exit_user_task -> true
                _ -> nil
              end
            end
          }
        ],
        initial_task: :call_process_task
      },
    %ProcessModel{
      name: :sub_process_with_one_user_task,
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

  test "load and retrieve process models" do
    PS.clear_state()
    PS.load_process_models(get_exit_event_on_sub_process())
    assert length(PS.get_process_models()) == 2

    simple_call_process_model = PS.get_process_model(:simple_call_process_model)
    assert simple_call_process_model != nil
    assert simple_call_process_model.name == :simple_call_process_model

    sub_process_with_one_user_task = PS.get_process_model(:sub_process_with_one_user_task)
    assert sub_process_with_one_user_task != nil
    assert sub_process_with_one_user_task.name == :sub_process_with_one_user_task
  end

  test "complete a user task" do
    PS.clear_then_load_process_models(TestModels.get_testing_process_models())
    data = %{value: 0}
    {:ok, ppid, uid} = PE.start_process(:user_task_process_model, data)
    PE.execute_and_wait(ppid)

    [task_instance] = Map.values(PE.get_open_tasks(ppid))

    PS.complete_user_task(ppid, task_instance.uid, %{user_task_complete: true})
    Process.sleep(50)

    assert PS.get_completed_process(uid) != nil
  end

  test "assign a task to a user" do
    PS.clear_then_load_process_models(TestModels.get_testing_process_models())
    PS.clear_user_tasks()
    {:ok, ppid, _uid} = PE.start_process(:one_user_task_process, %{value: 1})
    PE.execute(ppid)
    Process.sleep(10)
    [task] = PS.get_user_tasks_for_user("crirvine")
    PS.assign_user_task(task, "crirvine")
    [task] = PS.get_user_tasks_for_user("crirvine")
    assert task.assignee == "crirvine"
  end

  test "start a process engine" do
    PS.clear_then_load_process_models(TestModels.get_parallel_process_models())
    {:ok, ppid, uid} = PE.start_process(:parallel_process_model, %{value: 1})
    PE.execute(ppid)
    Process.sleep(10)

    completed_process = PS.get_completed_process(uid)
    assert completed_process.data == %{value: 1, final: :final, foo: :foo, bar: :bar, foo_bar: :foo_bar}
    assert completed_process.complete == true
  end
end
