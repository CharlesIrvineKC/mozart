# Mozart Task Types

In this guide we will provide examples of all of the Mozart BPM DSL functions.

If you want to follow along, create an Elixir mix project that has Mozart as a dependency.

```elixir
  defp deps do
    [
      {:mozart, "~> 0.3"}
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

* The **function** field specifies the function that the service task should apply for the purpose of returning output data into the process state.
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

Now, you need to load your process model into the system.

```elixir

iex [08:21 :: 3] > PS.load_process_models(MyBpmApplication.get_processes())
{:ok, ["add x and y process"]}
```

**ProcessService.load_process_models/1** loads your BPM process application models into the model repository.

**MyBpmApplication.get_processes/0** retrieves your process models from your BPM application. You didn't define this function in your module, but it was defined for you when you added **use Mozart.BpmProcess** to your module.

Now you are ready to start a **ProcessEngine** that will run your process model:

```elixir
iex [08:21 :: 4] > {:ok, ppid, uid, process_key} = PE.start_process("add x and y process", %{x: 1, y: 1})

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

**Important Note**: Users interact with a BPM platfrom such as Mozart by way of user application of some kind. The user application will allow the user to find tasks appropriate to his role. Once the user accepts responsibility for a task, the application will then provide a user interface input form appropriate for accomplishing the given task. For now, we will use Mozart functions for finding and completing tasks.

A user task has two unique arguments: **groups** and **:inputs**.

* The **groups** field specifies the user groups that are elibigle to complete the task. 
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
PS.load_process_models(MyBpmApplication.get_processes())
{:ok, ppid, uid, process_key} = PE.start_process("one user task process", %{x: 1, y: 1})
PE.execute(ppid)

```

and we should see:

```elixir
Interactive Elixir (1.16.2) - press Ctrl+C to exit (type h() ENTER for help)
iex [10:39 :: 1] > alias Mozart.ProcessEngine, as: PE
Mozart.ProcessEngine
iex [10:39 :: 2] > alias Mozart.ProcessService, as: PS
Mozart.ProcessService
iex [10:39 :: 3] > PS.load_process_models(MyBpmApplication.get_processes())
{:ok, ["add x and y process", "one user task process"]}
iex [10:39 :: 4] > {:ok, ppid, uid, process_key} = PE.start_process("one user task process", %{x: 1, y: 1})

10:39:49.816 [info] Start process instance [one user task process][714ff531-762f-4677-a357-dda88d7fb1c1]
{:ok, #PID<0.285.0>, "714ff531-762f-4677-a357-dda88d7fb1c1",
 "75a5124a-a51c-446f-80e7-d253dd3b5bc9"}
iex [10:39 :: 5] > PE.execute(ppid)
:ok

10:39:49.824 [info] New user task instance [user gives sum of x and y][3fc1cdf8-4049-40db-9172-9a7f58a85cb8]
```

The last log message tells us that a new user task was opened, but we don't see logs indicating that the task completed or that the process completed. That is because a user must be manually completed by a user.

To complete the user task, we need the process uid and the task uid. We have the process uid, since it was returned to us when we started the process engine. It should be in the variable **uid**.

We also have the task uid. It was printed in the last log statement:

```elixir
10:39:49.824 [info] New user task instance [user gives sum of x and y][3fc1cdf8-4049-40db-9172-9a7f58a85cb8]
```

It is the value in last pair of square brackets: "3fc1cdf8-4049-40db-9172-9a7f58a85cb8". 

The final thing we need to complete the task, is the data that we want to merge into the process data. We want to merge in the sum of the inputs **x** and **y**.

These inputs are avaiable on the task itself, and we can get the task by calling **ProcessService.get_user_task/1**, passing it the task uid. Let's do that now:

```elixir
iex [13:05 :: 7] > user_task = PS.get_user_task("3fc1cdf8-4049-40db-9172-9a7f58a85cb8")
%{
  complete: false,
  data: %{y: 1, x: 1},
  function: nil,
  name: "user gives sum of x and y",
  type: :user,
  next: nil,
  __struct__: Mozart.Task.User,
  uid: "3fc1cdf8-4049-40db-9172-9a7f58a85cb8",
  assigned_groups: ["admin"],
  duration: nil,
  finish_time: nil,
  inputs: [:x, :y],
  start_time: ~U[2024-06-30 18:05:45.563258Z],
  process_uid: "fca5f283-0992-4921-ba16-f9d902f9e403"
}
```

Notice that the task map has a **data** key, with the values of the **x and y inputs**. A GUI application for completing user tasks would have access to this data and would make it available to the user completing the task. So, let's assume that we know the value of our inputs and we use them to complete our task.

Let's do that now by calling ProcessService.complete_user_task/3. 

```elixir
PS.complete_user_task(uid, "3fc1cdf8-4049-40db-9172-9a7f58a85cb8", %{sum: 3})

```

and we should see:

```elixir
iex [13:05 :: 8] > PS.complete_user_task(uid, "7f3d7009-ab44-4955-a501-677e0a8a353b", %{sum: 3})
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
PS.load_process_models(MyBpmApplication.get_processes())
{:ok, ppid, uid, process_key} = PE.start_process("subprocess task process", %{value: 0})
PE.execute(ppid)

```

And you should see something like:

```elixir
iex [13:50 :: 1] > alias Mozart.ProcessEngine, as: PE
Mozart.ProcessEngine
iex [13:50 :: 2] > alias Mozart.ProcessService, as: PS
Mozart.ProcessService
iex [13:50 :: 3] > PS.load_process_models(MyBpmApplication.get_processes())
{:ok,
 ["add x and y process", "one user task process", "two service tasks",
  "subprocess task process"]}
iex [13:50 :: 4] > {:ok, ppid, uid, process_key} = PE.start_process("subprocess task process", %{value: 0})

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

Check.



