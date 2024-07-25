# Mozart Task Types

In this guide we will provide examples of all of the Mozart BPM DSL functions.

If you want to follow along, create an Elixir mix project that has Mozart as a dependency.

```elixir
  defp deps do
    [
      {:mozart, "~> 0.4"}
    ]
  end
```

Now, create an Elixir module named my_bpm_application.ex with the following contents:

```elixir
defmodule MyBpmApplication do
  use Mozart.BpmProcess

  # All of the examples will go here

end

```

## Service Task

A **Service Task** performs its work by calling an Elixir function. This function could perform a computation, call an external JSON service, retrieve data from a database, etc.

A service task has two unique arguments: **function** and **inputs**.

* The **function** field specifies the function that the service task should apply for the purpose of returning output data into the process state. The function can be either a captured function or an atom corresponding to a locally
defined function of arity 1.
* The **inputs** field is used to select which process data fields are passed to the task's function. If no value is supplied for this field, the entire process data is passed.

### Service Task example

In your MyBpmApplication module, enter the following code:

```elixir
defmodule MyBpmApplication do
  use Mozart.BpmProcess

  ## Service Task Example

  def sum(data) do
    %{sum: data.x + data.y}
  end

  defprocess "add x and y process" do
    service_task("add x and y task", function: &MyBpmApplication.sum/1, inputs: "x,y")
    # You could also specify:
    # service_task("add x and y task", function: :sum, inputs: "x,y")
  end

end

```

We've defined a process model that has a single service task. The name of the task is **"add x and y task"**. It will apply the function **MyBpmApplication.sum/1** to the arguments **x** and **y**.

Now open an iex session on your project:

```elixir
$ iex -S mix

```

Now, paste in a couple of alias's:

```elixir
alias Mozart.ProcessEngine, as: PE
alias Mozart.ProcessService, as: PS

```

Now, you need to load your process model into the system. Paste in the following:

```elixir
MyBpmApplication.load()

```

which gives the result:

```elixir
iex [16:41 :: 1] > MyBpmApplication.load()
{:ok,
 ["add x and y process"]}
```

**MyBpmApplication.load/0** loads your BPM process application models into the model repository. You didn't define this function in your module. It was defined for you when you added **use Mozart.BpmProcess** to your module.

Now you are ready to start a **ProcessEngine** that will run your process model:

```elixir
{:ok, ppid, uid, business_key} = PE.start_process("add x and y process", %{x: 1, y: 1})

```

You should then see:

```elixir
08:33:47.895 [info] Start process instance [add x and y process][299f3213-94ab-418d-bee3-18da04f2c38d]
{:ok, #PID<0.302.0>, "299f3213-94ab-418d-bee3-18da04f2c38d",
 "4d6e7fba-b303-4c9b-8cf5-a291168bd73d"}
```

Your process engine is now ready to execute your process model. Run the following function:

```elixir
iex [08:21 :: 5] > PE.execute(ppid)
:ok
08:37:46.418 [info] New service task instance [add x and y task][211308eb-fc1f-45f9-b758-077b12e920db]
08:37:46.418 [info] Complete service task [add x and y task[211308eb-fc1f-45f9-b758-077b12e920db]
08:37:46.418 [info] Process complete [add x and y process][299f3213-94ab-418d-bee3-18da04f2c38d]
```

As the log entires indicate:

* A new service task was created.
* The service task completed it work (by applying the function you specified).
* And finally the process completed.

To verify, that your process did what it was supposed to do, execute the following:

```elixir
iex [08:21 :: 6] > PS.get_completed_process_data(uid)
%{sum: 2, y: 1, x: 1}
```

## User Task

A **User Task** works by having a user complete some required task. This often takes the form of a user using a GUI to examine a subset of process data and then supplying additional data. 

**Important Note**: Users interact with a BPM platfrom such as Mozart by way of end user GUI application. The user application will allow the user to find tasks appropriate to his role. Once the user accepts responsibility for a task, the application will then provide an input form appropriate for accomplishing the given task. For now, we will use Mozart functions for finding and completing tasks.

A user task has two unique arguments: **groups** and **:inputs**.

* The **groups** field specifies the user groups in the form of a comma separated list that are elibigle to complete the task. 
* The **inputs** field is used to select which process data fields are passed to the user that will compleete the task. If no value is supplied for this field, the entire process data is passed.

### User Task example

First, let's add a process model containing a user task;

```elixir
defmodule MyBpmApplication do
  use Mozart.BpmProcess

  ## Previous Examples Omitted

  ## User Task Example

  defprocess "one user task process" do
    user_task("user gives sum of x and y", groups: "admin", inputs: "x,y")
  end

end

```

Now we drop back into iex:

```
iex -S mix
```

Now we paste in code to define alias's, load our process models, start a process engine and then execute our process model.

```elixir
alias Mozart.ProcessEngine, as: PE
alias Mozart.ProcessService, as: PS
MyBpmApplication.load()
{:ok, ppid, uid, business_key} = PE.start_process("one user task process", %{x: 1, y: 1})
PE.execute(ppid)

```

and we should see:

```elixir
Interactive Elixir (1.16.2) - press Ctrl+C to exit (type h() ENTER for help)
iex [10:39 :: 1] > alias Mozart.ProcessEngine, as: PE
Mozart.ProcessEngine
iex [10:39 :: 2] > alias Mozart.ProcessService, as: PS
Mozart.ProcessService
iex [10:39 :: 3] > MyBpmApplication.load()
{:ok, ["add x and y process", "one user task process"]}
iex [10:39 :: 4] > {:ok, ppid, uid, business_key} = PE.start_process("one user task process", %{x: 1, y: 1})

10:39:49.816 [info] Start process instance [one user task process][714ff531-762f-4677-a357-dda88d7fb1c1]
{:ok, #PID<0.285.0>, "714ff531-762f-4677-a357-dda88d7fb1c1",
 "75a5124a-a51c-446f-80e7-d253dd3b5bc9"}
iex [10:39 :: 5] > PE.execute(ppid)
:ok

10:39:49.824 [info] New user task instance [user gives sum of x and y][3fc1cdf8-4049-40db-9172-9a7f58a85cb8]
```

The last log message tells us that a new user task was opened, but we don't see logs indicating that the task completed or that the process completed. That is because a user task waits to be completed by a user.

To complete the user task we need the task uid, which was printed in the last log statement:

```elixir
10:39:49.824 [info] New user task instance [user gives sum of x and y][3fc1cdf8-4049-40db-9172-9a7f58a85cb8]
```

It is the value in last pair of square brackets: "3fc1cdf8-4049-40db-9172-9a7f58a85cb8". 

The final thing we need to complete the task is the data that we want to merge into the process data. We want to merge in the sum of the inputs **x** and **y**. A GUI application for completing user tasks would have access to this data and would make it available to the user completing the task. So, let's assume that we know the value of our inputs and we use them to complete our task.

Let's do that now by calling ProcessService.complete_user_task/2. 

```elixir
PS.complete_user_task("3fc1cdf8-4049-40db-9172-9a7f58a85cb8", %{sum: 3})

```

and we should see:

```elixir
iex [13:05 :: 8] > PS.complete_user_task("7f3d7009-ab44-4955-a501-677e0a8a353b", %{sum: 3})
:ok
13:16:21.326 [info] Complete user task [user gives sum of x and y][7f3d7009-ab44-4955-a501-677e0a8a353b]
13:16:21.327 [info] Process complete [one user task process][fca5f283-0992-4921-ba16-f9d902f9e403]
```

## Subprocess Task Example

The **Subprocess Task** is completed by calling a subprocess. When subprocess completes, the corresponding subprocess task also completes.

Update your MyBpmApplication module with the following code:

```elixir
defmodule MyBpmApplication do
  use Mozart.BpmProcess

  ## Previous Code Here

  ## Subprocess Task Example

  def add_one_to_value(data) do
    Map.put(data, :value, data.value + 1)
  end

  defprocess "two service tasks" do
    service_task("service task 2", function: &MyBpmApplication.add_one_to_value/1, inputs: "value")
    service_task("service task 3", function: &MyBpmApplication.add_one_to_value/1, inputs: "value")
  end

  defprocess "subprocess task process" do
    service_task("service task 1", function: &MyBpmApplication.add_one_to_value/1, inputs: "value")
    subprocess_task("subprocess task", model: "two service tasks")
  end

end

```

Now, we will open an iex session and to the following:

1. Paste in our alias'.
1. Load our process models.
1. Start a process engine with the process named "subprocess task process".
1. Execute the process.

Open your iex session and paste in:

```elixir
alias Mozart.ProcessEngine, as: PE
alias Mozart.ProcessService, as: PS
MyBpmApplication.load()
{:ok, ppid, uid, business_key} = PE.start_process("subprocess task process", %{value: 0})
PE.execute(ppid)

```

And you should see something like:

```elixir
iex [13:50 :: 1] > alias Mozart.ProcessEngine, as: PE
Mozart.ProcessEngine
iex [13:50 :: 2] > alias Mozart.ProcessService, as: PS
Mozart.ProcessService
iex [13:50 :: 3] > MyBpmApplication.load()
{:ok,
 ["add x and y process", "one user task process", "two service tasks",
  "subprocess task process"]}
iex [13:50 :: 4] > {:ok, ppid, uid, business_key} = PE.start_process("subprocess task process", %{value: 0})

13:50:13.910 [info] Start process instance [subprocess task process][903561d2-2f27-4014-9bf9-4334a0d93466]
{:ok, #PID<0.288.0>, "903561d2-2f27-4014-9bf9-4334a0d93466",
 "d16c2892-7419-4381-b060-e4d899d24ee6"}
iex [13:50 :: 5] > PE.execute(ppid)
:ok
13:50:13.912 [info] New service task instance [service task 1][ee364170-99ad-4ff9-8eda-e4c598e3d7da]
13:50:13.912 [info] Complete service task [service task 1[ee364170-99ad-4ff9-8eda-e4c598e3d7da]
13:50:13.913 [info] New sub_process task instance [subprocess task][251b46d7-bf0e-4818-bf28-45a628b85087]
13:50:13.913 [info] Start process instance [two service tasks][cd9cb03f-f50c-48f2-ba51-9ed4d31c18fa]
13:50:13.913 [info] New service task instance [service task 2][1f09acb8-b1ef-465e-9fe3-8f9a754f55e2]
13:50:13.913 [info] Complete service task [service task 2[1f09acb8-b1ef-465e-9fe3-8f9a754f55e2]
13:50:13.913 [info] New service task instance [service task 3][31bc8c0b-cd65-4e80-9afe-74fa546c7412]
13:50:13.913 [info] Complete service task [service task 3[31bc8c0b-cd65-4e80-9afe-74fa546c7412]
13:50:13.913 [info] Complete subprocess task [subprocess task][251b46d7-bf0e-4818-bf28-45a628b85087]
13:50:13.913 [info] Process complete [two service tasks][cd9cb03f-f50c-48f2-ba51-9ed4d31c18fa]
13:50:13.913 [info] Process complete [subprocess task process][903561d2-2f27-4014-9bf9-4334a0d93466]
```

If we examine the logs, we should see that what we expect to happen did happen.

When top level process finishes, we would expect the **value** parameter would have a value of three. Let's check if that is the case:

```elixir
iex [13:50 :: 6] > PS.get_completed_process_data(uid)
%{value: 3}
```

## Case Task Example

The **Case Task** provides a way to specify alternate execution paths depending on the current state of process execution.

Add the following content to the MyBpmApplication module:

```elixir
defmodule MyBpmApplication do
  use Mozart.BpmProcess

  ## Previous content here

  ## Case Task Example

  def add_two_to_value(data) do
    Map.put(data, :value, data.value + 2)
  end

  def subtract_two_from_value(data) do
    Map.put(data, :value, data.value - 2)
  end

  def x_less_than_y(data) do
    data.x < data.y
  end

  def x_greater_or_equal_y(data) do
    data.x >= data.y
  end

  defprocess "two case process" do
    case_task "yes or no" do
      case_i &MyBpmApplication.x_less_than_y/1 do
        service_task("1", function: &MyBpmApplication.subtract_two_from_value/1, inputs: "value")
        service_task("2", function: &MyBpmApplication.subtract_two_from_value/1, inputs: "value")
      end
      case_i :x_greater_or_equal_y do
        service_task("3", function: &MyBpmApplication.add_two_to_value/1, inputs: "value")
        service_task("4", function: &MyBpmApplication.add_two_to_value/1, inputs: "value")
      end
    end
  end

end
```

The first argument to **case_task** is a task name and the second argument is a block of cases.

The first argument to **case_i** is either a captured function of arity 1 or an atom corresponding to a locally defined function of arity 1. The second argument is a block of tasks.

The process named "two case process" performs this logic:

* If **x is less than y**, subtract 2 from the value parameter twice.
* if **x is greater or equal to y**, add 2 to the value parameter twice.

Let's try it out. Open an iex session, and paste in the following:

```elixir
alias Mozart.ProcessEngine, as: PE
alias Mozart.ProcessService, as: PS
MyBpmApplication.load()
{:ok, ppid, uid, business_key} = PE.start_process("two case process", %{x: 1, y: 2, value: 10})
PE.execute(ppid)

```
and you should see:

```elixir
iex [14:33 :: 1] > alias Mozart.ProcessEngine, as: PE
Mozart.ProcessEngine
iex [14:33 :: 2] > alias Mozart.ProcessService, as: PS
Mozart.ProcessService
iex [14:33 :: 3] > MyBpmApplication.load()
{:ok,
 ["add x and y process", "one user task process", "two service tasks",
  "subprocess task process", "two case process"]}
iex [14:33 :: 4] > {:ok, ppid, uid, business_key} = PE.start_process("two case process", %{x: 1, y: 2, value: 10})

14:33:41.084 [info] Start process instance [two case process][4fb6889e-250c-407e-a332-f904f491b39d]
{:ok, #PID<0.285.0>, "4fb6889e-250c-407e-a332-f904f491b39d",
 "f5a76516-1509-4e01-99dd-949dba2c06c4"}
iex [14:33 :: 5] > PE.execute(ppid)
:ok
14:33:41.088 [info] New case task instance [yes or no][4a7fd5c1-eaa5-4cfc-9edf-73bd28eaa9cb]
14:33:41.088 [info] Complete case task [yes or no][4a7fd5c1-eaa5-4cfc-9edf-73bd28eaa9cb]
14:33:41.088 [info] New service task instance [1][6482abb3-c56f-43d7-870f-83789b77135b]
14:33:41.088 [info] Complete service task [1[6482abb3-c56f-43d7-870f-83789b77135b]
14:33:41.089 [info] New service task instance [2][7ee68e1e-9823-4e92-9613-e34f1c279c3a]
14:33:41.089 [info] Complete service task [2[7ee68e1e-9823-4e92-9613-e34f1c279c3a]
14:33:41.089 [info] Process complete [two case process][4fb6889e-250c-407e-a332-f904f491b39d]
```

Based on our input data, since x was less than y, 2 should have been subtracted from 10 twice, leaving the **value** parameter with a value of 6. Let's see if that matches our result:

```elixir
iex [13:50 :: 6] > PS.get_completed_process_data(uid)
%{value: 6, y: 2, x: 1}
```

## Send and Receive Task Example

For this example, we will use both the Send and Receive tasks since they are typically used together, that is, a receive task receives a messge from a send task.

Update the MyBpmApplication module with the following content:

```elixir
defmodule MyBpmApplication do
  use Mozart.BpmProcess

  ## Previous Content Here

  ## Send and Receive Example

  def receive_loan_income(msg) do
    case msg do
      {:barrower_income, income} -> %{barrower_income: income}
      _ -> nil
    end
  end

  defprocess "receive barrower income process" do
    receive_task("receive barrower income", selector: &MyBpmApplication.receive_loan_income/1)
  end

  defprocess "send barrower income process" do
    send_task("send barrower income", message: {:barrower_income, 100_000})
  end

end

```

In this example we will start the "receive barrower income process" first. The "receive barrower income" task will wait until it receives a message of the form **{:barrower_income, income}**. When it receives this message it will merge **%{barrower_income: income}** into the processes data.

The purpose of the "send barrower income process" task is to send the message that the receive task is waiting for.

Open an iex session, and paste in the following:

```elixir
alias Mozart.ProcessEngine, as: PE
alias Mozart.ProcessService, as: PS
MyBpmApplication.load()
{:ok, ppid, uid, business_key} = PE.start_process("receive barrower income process", %{})
PE.execute(ppid)

```

and you should see:

```elixir
iex [17:23 :: 1] > alias Mozart.ProcessEngine, as: PE
Mozart.ProcessEngine
iex [17:23 :: 2] > alias Mozart.ProcessService, as: PS
Mozart.ProcessService
iex [17:23 :: 3] > MyBpmApplication.load()
{:ok,
 ["add x and y process", "one user task process", "two service tasks",
  "subprocess task process", "two case process",
  "receive barrower income process", "send barrower income process"]}
iex [17:23 :: 4] > {:ok, ppid, uid, business_key} = PE.start_process("receive barrower income process", %{})

17:23:16.604 [info] Start process instance [receive barrower income process][d9534434-acc0-43a3-83ac-2f6db76cfb3d]
{:ok, #PID<0.296.0>, "d9534434-acc0-43a3-83ac-2f6db76cfb3d",
 "82d4ac32-e192-4a4b-a5e9-29f02c7ee46a"}
iex [17:23 :: 5] > PE.execute(ppid)
:ok

17:23:16.608 [info] New receive task instance [receive barrower income][8286148c-a756-4db9-b21b-86acb3e8d17a]
```

At this point, we've started the process with the receive task and we see that the expected receive task has been opened. Now we need to run the process with the send task so the waiting receive task can complete. To do that, copy the following into your iex session. 

```elixir
{:ok, s_ppid, s_uid, s_business_key} = PE.start_process("send barrower income process", %{})
PE.execute(s_ppid)

```

Notice that when we call **PE.start_process/2**, we choose different varaible names so that our previous variable values won't be overwirtten.


You should see this result:

```elixir
iex [17:23 :: 6] > {:ok, ppid, uid, business_key} = PE.start_process("send barrower income process", %{})

17:28:56.665 [info] Start process instance [send barrower income process][d58a5b10-1a12-48f5-9426-9ab90701e933]
{:ok, #PID<0.299.0>, "d58a5b10-1a12-48f5-9426-9ab90701e933",
 "7e9657d1-21ba-40e4-8c42-00f913c62926"}
iex [17:23 :: 7] > PE.execute(ppid)
:ok
17:28:56.666 [info] New send task instance [send barrower income][273a9f29-783c-4306-97c4-eb9e12735a80]
17:28:56.667 [info] Complete send event task [send barrower income[273a9f29-783c-4306-97c4-eb9e12735a80]
17:28:56.667 [info] Complete receive event task [receive barrower income]
17:28:56.667 [info] Process complete [send barrower income process][d58a5b10-1a12-48f5-9426-9ab90701e933]
17:28:56.667 [info] Process complete [receive barrower income process][d9534434-acc0-43a3-83ac-2f6db76cfb3d]
```

Now we can check whether the expected data was merged into the process data of the first process:

```elixir
iex [17:38 :: 8] > PS.get_completed_process_data(uid)
%{barrower_income: 100000}
```

## Parallel and Prototype Task Example

A **Parallel Task** provides the ability to start two or more parallel execution paths. A **Prototype Task** has no behavior. A process engine will complete it automatically after it is opened. It is primarily used for stubbing tasks that will be replaced later with one of the other task types.

Copy the following content into MyBpmApplication module:

```elixir
defmodule MyBpmApplication do
  @moduledoc false
  use Mozart.BpmProcess

  ## Previous Content Here

  ## Parallel and Prototype Task Example

  defprocess "two parallel routes process" do
    parallel_task "a parallel task" do
      route do
        prototype_task("prototype task 1")
        prototype_task("prototype task 2")
      end
      route do
        prototype_task("prototype task 3")
        prototype_task("prototype task 4")
      end
    end
  end

end

```

Now open an iex session and copy is the following:

```elixir
alias Mozart.ProcessEngine, as: PE
alias Mozart.ProcessService, as: PS
MyBpmApplication.load()
{:ok, ppid, uid, business_key} = PE.start_process("two parallel routes process", %{})
PE.execute(ppid)

```

You should see:

```elixir
iex [18:29 :: 1] > alias Mozart.ProcessEngine, as: PE
Mozart.ProcessEngine
iex [18:29 :: 2] > alias Mozart.ProcessService, as: PS
Mozart.ProcessService
iex [18:29 :: 3] > MyBpmApplication.load()
{:ok,
 ["add x and y process", "one user task process", "two service tasks",
  "subprocess task process", "two case process",
  "receive barrower income process", "send barrower income process",
  "two parallel routes process"]}
iex [18:29 :: 4] > {:ok, ppid, uid, business_key} = PE.start_process("two parallel routes process", %{})

18:29:26.105 [info] Start process instance [two parallel routes process][08dba7e3-820e-4ea4-985e-5184b8041c80]
{:ok, #PID<0.323.0>, "08dba7e3-820e-4ea4-985e-5184b8041c80",
 "f4753b53-68ad-404b-ae0c-27bc9737b032"}
iex [18:29 :: 5] > PE.execute(ppid)
:ok
18:29:26.108 [info] New parallel task instance [a parallel task][f7aa1870-e01a-46fb-8e0e-9a4353001241]
18:29:26.108 [info] Complete parallel task [a parallel task]
18:29:26.108 [info] New prototype task instance [prototype task 1][609a01d8-c7bd-4539-ad4e-720951ab56a3]
18:29:26.109 [info] New prototype task instance [prototype task 3][16cc3d11-d8cb-4111-9b53-439a4cb10b94]
18:29:26.109 [info] Complete prototype task [prototype task 3]
18:29:26.109 [info] New prototype task instance [prototype task 4][e03c4cb7-e16d-45d4-98c1-4380bd57d240]
18:29:26.109 [info] Complete prototype task [prototype task 1]
18:29:26.109 [info] New prototype task instance [prototype task 2][48402cb3-9274-4da8-9b50-13e0a8b4b77e]
18:29:26.109 [info] Complete prototype task [prototype task 2]
18:29:26.109 [info] Complete prototype task [prototype task 4]
18:29:26.109 [info] Process complete [two parallel routes process][08dba7e3-820e-4ea4-985e-5184b8041c80]
```

Examime the log messages. You should be able to see that two execution paths were proceeding in parallel.

## Repeat Task Example

The **Repeat Task** provides the ability to repeat a set of tasks as long a specified condition holds true.

Copy the following new code into the MyBpmApplication module:

```elixir
defmodule MyBpmApplication do
  @moduledoc false
  use Mozart.BpmProcess

  ## Previous content here

  def continue(data) do
    data.continue
  end

  defprocess "repeat task process" do
    repeat_task "repeat task", &ME.continue/1 do
      prototype_task("prototype task 1")
      prototype_task("prototype task 2")
      user_task("user task", groups: "admin")
    end
    prototype_task("last prototype task")
  end

end

```

Open an iex session and paste in the following:

```elixir
alias Mozart.ProcessEngine, as: PE
alias Mozart.ProcessService, as: PS
MyBpmApplication.load()
{:ok, ppid, uid, business_key} = PE.start_process("repeat task process", %{continue: true})
PE.execute(ppid)

```

and you should see:

```elixir
iex [09:10 :: 4] > alias Mozart.ProcessEngine, as: PE
Mozart.ProcessEngine
iex [09:10 :: 5] > alias Mozart.ProcessService, as: PS
Mozart.ProcessService
iex [09:10 :: 6] > MyBpmApplication.load()
{:ok,
 ["add x and y process", "one user task process", "two service tasks",
  "subprocess task process", "two case process",
  "receive barrower income process", "send barrower income process",
  "two parallel routes process", "repeat task process"]}
iex [09:10 :: 7] > {:ok, ppid, uid, business_key} = PE.start_process("repeat task process", %{continue: true})

09:11:31.919 [info] Start process instance [repeat task process][e3963cb8-410d-4039-ad81-eb6730808783]
{:ok, #PID<0.300.0>, "e3963cb8-410d-4039-ad81-eb6730808783",
 "ba5bded6-fbd9-4690-9643-453ab31457fa"}
iex [09:10 :: 8] > PE.execute(ppid)
:ok
09:11:31.923 [info] New repeat task instance [repeat task][b600cf3d-8f84-4d16-8378-96f0bb152440]
09:11:31.923 [info] New prototype task instance [prototype task 1][c6f6cfca-7097-4931-bea4-61404160e5d1]
09:11:31.923 [info] Complete prototype task [prototype task 1]
09:11:31.923 [info] New prototype task instance [prototype task 2][4c526ace-eb2b-4d7d-b918-83f1deda831f]
09:11:31.923 [info] Complete prototype task [prototype task 2]
09:11:31.924 [info] New user task instance [user task][2557b2e6-d6fa-4172-b25b-a809633e5217]
```

Now, let's complete the user task specifying **continue to be true***, i.e. %{continue: true}. This should cause the repeat tasks to be executed one more time:

```elixir
PS.complete_user_task("2557b2e6-d6fa-4172-b25b-a809633e5217", %{continue: true})

```

The output verifies this is the case:

```elixir
iex [09:10 :: 9] > PS.complete_user_task("2557b2e6-d6fa-4172-b25b-a809633e5217", %{continue: true})
:ok
09:17:20.481 [info] New prototype task instance [prototype task 1][4af087bb-865b-41b5-8d6b-55e6c9511d2b]
09:17:20.481 [info] Complete user task [user task][2557b2e6-d6fa-4172-b25b-a809633e5217]
09:17:20.481 [info] Complete prototype task [prototype task 1]
09:17:20.481 [info] New prototype task instance [prototype task 2][965fa775-6280-43d0-ab50-8a966ed69dac]
09:17:20.481 [info] Complete prototype task [prototype task 2]
09:17:20.481 [info] New user task instance [user task][2e855696-e11d-42e7-89a9-330c2a87b11f]
```

Now, let's complete the new user task with **%{continue: false}**. This should cause the repeat to complete, the final **prototype_task** to complete and then the process to complete:

```elixir
PS.complete_user_task("2e855696-e11d-42e7-89a9-330c2a87b11f", %{continue: false})

```

And we see the following, which verifies the expected behavior:

```elixir
iex [09:10 :: 10] > PS.complete_user_task("2e855696-e11d-42e7-89a9-330c2a87b11f", %{continue: false})
:ok
09:23:09.731 [info] Complete user task [user task][2e855696-e11d-42e7-89a9-330c2a87b11f]
09:23:09.732 [info] Complete repeat task [repeat task]
09:23:09.732 [info] New prototype task instance [last prototype task][5b6c63db-46bb-459b-a79f-d0c53a1662ca]
09:23:09.732 [info] Complete prototype task [last prototype task]
09:23:09.732 [info] Process complete [repeat task process][e3963cb8-410d-4039-ad81-eb6730808783]
```

## Rule Task Example

A **Rule Task** completes by evaluating a set of rules in a *rule table* and returning a derived value.

Copy the following new code into the MyBpmApplication module:

```elixir
defmodule MyBpmApplication do
  @moduledoc false
  use Mozart.BpmProcess

  ## Previous content here

  rule_table = """
  F     income      || status
  1     > 50000     || approved
  2     <= 49999    || declined
  """

  defprocess "single rule task process" do
    rule_task("loan decision", inputs: "income", rule_table: rule_table)
  end

```

Our table assumes there is a data property named **income**. If the value of *income* is greater than *50000*, the rule will return a property named **status** with a value of **approved**. If income is less than 50000, the value of *status* will be **declined**.

[**Note**: Mozart uses the Tablex library for rule tasks. Tablex is very powerful. [Complete documentation is available in hexdocs](https://hexdocs.pm/tablex/readme.html).]

Open an iex session on your project and paste in:

```elixir
alias Mozart.ProcessEngine, as: PE
alias Mozart.ProcessService, as: PS
MyBpmApplication.load()
{:ok, ppid, uid, business_key} = PE.start_process("single rule task process", %{income: 60_000})
PE.execute(ppid)

```

and you should see:

```elixir
iex [16:31 :: 3] > MyBpmApplication.load()
{:ok, .... deleted list of process names}
iex [16:31 :: 4] > {:ok, ppid, uid, business_key} = PE.start_process("single rule task process", %{income: 60_000})
16:31:29.857 [info] Start process instance [single rule task process][371b788e-33e6-4d55-9e0c-9e238f552b84]
{:ok, #PID<0.299.0>, "371b788e-33e6-4d55-9e0c-9e238f552b84",
 "83e7bb9a-a732-44b2-bdc3-ae4bbf6c1790"}
iex [16:31 :: 5] > PE.execute(ppid)
:ok
16:31:29.860 [info] New rule task instance [loan decision][ab9ef596-0be3-44de-a66a-6fb41eaf0ab6]
16:31:29.860 [info] Complete run task [loan decision[ab9ef596-0be3-44de-a66a-6fb41eaf0ab6]
16:31:29.863 [info] Process complete [single rule task process][371b788e-33e6-4d55-9e0c-9e238f552b84]
```

Now let's look at the completed process data to see the property returned from the evaluation of the table:

```elixir
iex [16:31 :: 6] > PS.get_completed_process_data(uid)
%{status: "approved", income: 60000}
```

The value of **status** is **"approved"**, as expected.


