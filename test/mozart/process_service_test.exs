defmodule Mozart.ProcessServiceTest do
  use ExUnit.Case

  alias Mozart.ProcessService, as: PS
  alias Mozart.ProcessEngine, as: PE

  alias Mozart.Data.ProcessModel

  alias Mozart.Task.User
  alias Mozart.Task.Case
  alias Mozart.Task.Subprocess

  alias Mozart.Event.TaskExit

  setup do
    PS.clear_user_tasks()
  end

  def get_home_loan_process do
    %ProcessModel{
      name: :home_loan_process,
      tasks: [
        %User{
          name: :perform_pre_approval,
          inputs: [:credit_score, :income, :debt_amount],
          assigned_groups: ["credit"],
          next: :route_on_pre_approval_completion
        },
        %Case{
          name: :route_on_pre_approval_completion,
          cases: [
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
          inputs: [:credit_score, :income, :debt_amount],
          assigned_groups: ["credit"],
          next: :process_loan
        },
        %User{
          name: :process_loan,
          inputs: [:purchase_price, :credit_score, :income, :debt_amount],
          assigned_groups: ["credit"],
          next: :process_loan_outcome
        },
        %Case{
          name: :process_loan_outcome,
          cases: [
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
          inputs: [:purchase_price, :credit_score, :income, :debt_amount, :loan_verified],
          assigned_groups: ["underwriting"],
          next: :route_from_underwriting
        },
        %Case{
          name: :route_from_underwriting,
          cases: [
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
          inputs: [:loan_approved],
          assigned_groups: ["credit"]
        },
        %User{
          name: :communicate_loan_denied,
          inputs: [:loan_approved],
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
    {:ok, ppid, uid, _business_key} = PE.start_process(:home_loan_process, data)
    PE.execute(ppid)
    Process.sleep(100)

    ## complete pre approval
    [user_task] = PS.get_user_tasks_for_groups(["credit"])
    PS.complete_user_task(user_task.uid, %{pre_approval: true})
    Process.sleep(100)

    ## complete receive mortgage application
    [user_task] = PS.get_user_tasks_for_groups(["credit"])
    PS.complete_user_task(user_task.uid, %{purchase_price: 500_000})
    Process.sleep(100)

    ## process loan
    [user_task] = PS.get_user_tasks_for_groups(["credit"])
    PS.complete_user_task(user_task.uid, %{loan_verified: true})
    Process.sleep(100)

    ## perform underwriting
    [user_task] = PS.get_user_tasks_for_groups(["underwriting"])
    PS.complete_user_task(user_task.uid, %{loan_approved: true})
    Process.sleep(100)

    ## communicate approval
    [user_task] = PS.get_user_tasks_for_groups(["credit"])
    PS.complete_user_task(user_task.uid, %{loan_approved: true})
    Process.sleep(100)

    completed_process = PS.get_completed_process(uid)
    completed_tasks = completed_process.completed_tasks
    assert Enum.all?(completed_tasks, fn t -> t.duration end) == true
  end

  defp get_exit_event_on_sub_process do
    [
      %ProcessModel{
        name: :simple_call_process_model,
        tasks: [
          %Subprocess{
            name: :call_process_task,
            model: :subprocess_with_one_user_task
          }
        ],
        events: [
          %TaskExit{
            name: :exit_sub_process,
            exit_task: :call_process_task,
            selector: fn msg ->
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
      name: :subprocess_with_one_user_task,
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

    sub_process_with_one_user_task = PS.get_process_model(:subprocess_with_one_user_task)
    assert sub_process_with_one_user_task != nil
    assert sub_process_with_one_user_task.name == :subprocess_with_one_user_task
  end

  test "set active process groups" do
    state = %{active_process_groups: %{}}
    key = :key_1
    uid = :uid_1; pid = :pid_1;
    state = PS.get_active_process_groups(uid, pid, key, state)
    uid = :uid_2; pid = :pid_2
    state = PS.get_active_process_groups(uid, pid, key, state)
    key = :key_2
    uid = :uid_3; pid = "pid_4"
    state = PS.get_active_process_groups(uid, pid, key, state)
    assert state == %{
      active_process_groups: %{
        key_1: %{uid_1: :pid_1, uid_2: :pid_2},
        key_2: %{uid_3: "pid_4"}
      }
    }
  end
end
