# Home Loan Example

In this guide we will construct and execute a somewhat more complex process model than we have dealt with thus far. We will mainly use **user tasks** because they allow us to easily control of the process execution path during process execution.

We will create a process model applying for a home loan from a bank. It will be highly simplified compared to the actual process, but complicated enough for our purposes here.

Here is a summary of the loan approval process:

1. Get pre-approval from the bank for a loan. They will require a credit score, yearly income and the extent of the applicant's indebtedness.
1. After the applicant secures a contract on a house, he will fill out a complete loan application. Part of that will be the purchase price of the house.
1. Now the bank will process the applicant's loan application. This is to ensure that everything is in order and they have everything that they need.
1. After the loan has been processed, it will go to the underwriting department to determine whether the loan will be approved or not.
1. Finally, after the loan is approced, the bank will notify the applicant that the loan is approved.

If you are following along, open an iex session for a project Elixir project that has Mozart as a dependency.

Create a file home_loan.ex with the following content. The file will contain the complete process matching the process described above.

```elixir
defmodule HomeLoanApp do
  @moduledoc false
  use Mozart.BpmProcess

  alias HomeLoanApp, as: ME

  def pre_approved(data) do
    data.pre_approval
  end

  def pre_approval_declined(data) do
    not data.pre_approval
  end

  defprocess "home loan process" do
    user_task("perform pre approval", groups: "credit")

    case_task("route on pre approval completion", [
      case_i &ME.pre_approved/1 do

        user_task("receive mortgage application", groups: "credit")
        user_task("process loan", groups: "credit")
        subprocess_task("perform loan evaluation", model: "perform loan evaluation process")

      end,
    case_i &ME.pre_approval_declined/1 do

        user_task("communicate loan denied", groups: "credit")
    end
    ])
  end


def loan_verified(data) do
  data.loan_verified
end

def loan_failed_verification(data) do
  ! data.loan_verified
end

defprocess "perform loan evaluation process" do
  case_task "process loan outcome" do
    case_i &ME.loan_verified/1 do

      user_task("perform underwriting", groups: "underwriting")
      subprocess_task("route from underwriting", model: "route from underwriting process")

    end
    case_i &ME.loan_failed_verification/1 do

      user_task("communicate loan denied", groups: "credit")
    end
  end
end

def loan_approved(data) do
  data.loan_approved
end

def loan_declined(data) do
  ! data.loan_approved
end

defprocess "route from underwriting process" do
  case_task("route from underwriting", [
    case_i &ME.loan_approved/1 do

      user_task("communicate approval", groups: "credit")
    end
    case_i &ME.loan_declined/1 do

      user_task("communicate loan declined", groups: "customer_service")
    end
  ])
end

end

```

Now open an iex session on your project and paste in the following:

```elixir
  alias Mozart.ProcessService, as: PS
  alias Mozart.ProcessEngine, as: PE

  PS.load_process_models(HomeLoanApp.get_processes())

  {:ok, ppid, uid, process_key} = PE.start_process("home loan process", %{})

  PE.execute(ppid)

```

and you should see that a user task was opened:

```elixir
18:53:36.111 [info] New user task instance [perform pre approval][240a7811-b552-40c9-bbce-a75768e56d12]
```

This task is asking us to specify whether the loan should be pre approved. Let's complete the task in the affirmative.

```elixir
PS.complete_user_task(uid, "240a7811-b552-40c9-bbce-a75768e56d12", %{pre_approval: true})

```

Now we see that a new task has been opened:

```elixir
 New user task instance [receive mortgage application][ed0adc9a-0b55-466b-a7e1-4c7fb6712d99]
```

Now we need to complete this task when receive a mortgage contract from the customer. Let's do that:

```elixir
PS.complete_user_task(uid, "ed0adc9a-0b55-466b-a7e1-4c7fb6712d99", %{})

```

A new task was created:

```elixir
19:05:48.515 [info] New user task instance [process loan][75350759-1613-4c0e-8fbc-8dedda264121]
```

And we will complete that task like this:

```elixir
PS.complete_user_task(uid, "75350759-1613-4c0e-8fbc-8dedda264121", %{loan_verified: true})

```

And now the following task was created, and, importantly it was created in a new subprocess. Here are the two relevant log entries:

```elixir
19:08:41.990 [info] Start process instance [perform loan evaluation process][f0c978e9-f5f0-403f-97c1-c0a9fe459f63]
19:08:41.990 [info] New user task instance [perform underwriting][a163d0bb-a5c2-43b9-93bf-25beb4961238]
```

Now we need to complete "prform underwriting task" using the new process uid:

```elixir
PS.complete_user_task("f0c978e9-f5f0-403f-97c1-c0a9fe459f63", "a163d0bb-a5c2-43b9-93bf-25beb4961238", %{loan_approved: true})

```

Again, a new process was started and a new task was opened in it:

```elixir
19:13:35.639 [info] Start process instance [route from underwriting process][a7be20fe-4d3b-473e-bf58-3b85fcba474f]
19:13:35.640 [info] New user task instance [communicate approval][7617f9a7-660c-48f1-bf29-698f6eaa9d6e]
```

Let's complete that task:

```elixir
PS.complete_user_task("a7be20fe-4d3b-473e-bf58-3b85fcba474f", "7617f9a7-660c-48f1-bf29-698f6eaa9d6e", %{})

```

Finally, our top level process is complete, as indicated in the log message:

```elixir
19:17:42.130 [info] Process complete [home loan process][baa48cc2-f315-48f4-a4f1-97da78a16fe7]
```

This might have been a bit much to fully comprehend in one pass. Try stepping through it again, perhaps completing user tasks with different parameter values. Once you fully understand this example, you have pretty figured Mozart out!