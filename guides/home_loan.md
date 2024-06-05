# Home Loan Example

In this guide we will construct and execute a somewhat complex process model. We will mainly use **user tasks** because they allow user control of the process execution path.

We will create a process model applying for a home loan. It will be highly simplified compared to the actual process used by lending institutions, but complicated enough for our purposes here.

Here is a summary of the loan approval process:

1. Get pre-approval from the bank for a loan. They will require a credit score, yearly income and the extent indebtedness.
1. After you have a contract on a house, you will fill out a complete loan application. Part of that will be the purchase price of the house.
1. Now the bank will process your loan. This entails ensure that everything is in order and they have everything that they need.
1. After the loan has been processed, it will go to the underwriting department to determine whether the loan will be approved or not.
1. Finally, after the loan is approced, the bank will notify you that the loan is approved.

If you are following along, open an Elixir project that has Mozart as a dependency.

```
iex -S mix

```

Now paste the following alias' into your iex session

```
  alias Mozart.ProcessService, as: PS
  alias Mozart.ProcessEngine, as: PE
  alias Mozart.Data.ProcessModel
  alias Mozart.Task.User
  alias Mozart.Task.Choice

```

The following is our loan processing process model. At this point, you might try to map the process model to the summary of the process given above.

When you are ready, paste the process model into your iex session:

```
model = 
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

```

Now let's start executing this process. Paste the following into your iex session:

```
PS.clear_state()
PS.load_process_model(model)
data = %{credit_score: 700, income: 100_000, debt_amount: 20_000}
{:ok, ppid, _uid} = PE.start_process(:home_loan_process, data)
PE.execute(ppid)

```

At this point, the user task to perform pre-approval should have been opened:

```
[user_task] = PS.get_user_tasks_for_groups(["credit"])

```

which returns:

```
iex [11:54 :: 13] > [user_task] = PS.get_user_tasks_for_groups(["credit"])
[
  %{
    complete: false,
    data: %{credit_score: 700, income: 100000, debt_amount: 20000},
    function: nil,
    name: :perform_pre_approval,
    type: :user,
    next: :route_on_pre_approval_completion,
    __struct__: Mozart.Task.User,
    uid: "a987e7f0-15ba-422d-a26d-7ff6a6bdaaad",
    assigned_groups: ["credit"],
    input_fields: [:credit_score, :income, :debt_amount],
    process_uid: "5ece8627-623b-46f1-afa2-0fb11659a874"
  }
]
```

Let's assume that is sufficient information for granting pre-approval. We can do this like so:

```
 PS.complete_user_task(ppid, user_task.uid, %{pre_approval: true})

```

At this point, the choice task should have completed and routed the process to the user task **receive_mortgage_application**. The task will be completed when the loan applicant provides the bank with an mortgage application for a house that has been selected for purchase. The bank user will complete this task by entering the purchase price of the house.

Let's do that now:

```
[user_task] = PS.get_user_tasks_for_groups(["credit"])
PS.complete_user_task(ppid, user_task.uid, %{purchase_price: 500_000})

```

We have now accepted the customers loan application and noted that the purchase price is $500,000. We are ready to process the loan. Loan processsing is the bank's procedure to ensure that all of the information gathers thus far is in order. A user task for processing the loan should now be open. Let's check that it is:

```
[user_task] = PS.get_user_tasks_for_groups(["credit"])

```

which produces:

```
iex [18:16 :: 17] > [user_task] = PS.get_user_tasks_for_groups(["credit"])
[
  %{
    complete: false,
    data: %{
      credit_score: 700,
      income: 100000,
      debt_amount: 20000,
      purchase_price: 500000
    },
    function: nil,
    name: :process_loan,
    type: :user,
    next: :process_loan_outcome,
    __struct__: Mozart.Task.User,
    uid: "2aa15c30-b147-469d-b8a5-34946b2165df",
    assigned_groups: ["credit"],
    input_fields: [:purchase_price, :credit_score, :income, :debt_amount],
    process_uid: "8d106b1c-32f4-43b6-a168-e663bb59056f"
  }
]
```

Now let's complete that task, asserting that the loan has been verified:

```
PS.complete_user_task(ppid, user_task.uid, %{loan_verified: true})

```

Now we are ready for the underwriting department to assess whether the loan should be approved. Let's query for the task and approve the loan:

```
[user_task] = PS.get_user_tasks_for_groups(["underwriting"])
PS.complete_user_task(ppid, user_task.uid, %{loan_approved: true})

```

We are now ready for the final task of our process - informing the customer that the loan has been approved. Let's do that now:

```
[user_task] = PS.get_user_tasks_for_groups(["credit"])
PS.complete_user_task(ppid, user_task.uid, %{loan_approved: true})

```

At this point, our logs should indicate that the process has finished, as indeed we do:

```
iex [18:16 :: 23] > PS.complete_user_task(ppid, user_task.uid, %{loan_approved: true})
:ok
18:46:03.183 [info] Complete user task [communicate_approval][53a2b9ae-ba89-49f2-beba-0fdd8f49ab1f]
18:46:03.183 [info] Process complete [home_loan_process][8d106b1c-32f4-43b6-a168-e663bb59056f]
```

Now let's start at the beginning, and enter data so that the process completes with the loan being declined:

```
PS.clear_state()
PS.load_process_model(model)
data = %{credit_score: 700, income: 100_000, debt_amount: 20_000}
{:ok, ppid, _uid} = PE.start_process(:home_loan_process, data)
PE.execute(ppid)

```

Now, instead of granting pre-approval, let's decline the loan with the following:

```
[user_task] = PS.get_user_tasks_for_groups(["credit"])
PS.complete_user_task(ppid, user_task.uid, %{pre_approval: false})

```

We see in the last log entry, that we have a new **communicate_loan_denied** task.

```
iex [18:16 :: 32] > PS.complete_user_task(ppid, user_task.uid, %{pre_approval: false})
:ok
18:53:57.138 [info] New task instance [route_on_pre_approval_completion][645b421a-11ef-461e-91a7-7aa7e7fc66e6]
18:53:57.138 [info] Complete user task [perform_pre_approval][3ee4b0d2-1432-4d54-b248-34ae928db983]
18:53:57.138 [info] Complete choice task [route_on_pre_approval_completion][645b421a-11ef-461e-91a7-7aa7e7fc66e6]
18:53:57.139 [info] New task instance [communicate_loan_denied][a6a5bacd-a5a4-4b1e-a39b-99c0c8b58d04]
```

Let's complete that task now:

```
[user_task] = PS.get_user_tasks_for_groups(["credit"])
PS.complete_user_task(ppid, user_task.uid, %{loan_approved: false})

```





