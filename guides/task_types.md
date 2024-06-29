# Mozart Task Types

## Service Task

A **Service Task** performs its work by calling an Elixir function. This function could perform a computation, call an external JSON service, retrieve data from a database, etc.

A service task has two unique fields: **function** and **inputs**.

* The **function** field specifies the function that the service task should apply for the purpose of returning output data into the process state.
* The **inputs** field is used to select which process data fields are passed to the task's function. If no value is supplied for this field, the entire process data is passed.

### Service Task example

If you are following along, open an Elixir project that has Mozart as a dependency.

```
iex -S mix

```

Now paste the following alias' into your iex session

```

```

Now define a process model with a single service task and assign it to a variable:

```


```

We have specified that state data properties **:x** and **:y** should be available to the task's function. 

The task function will take the sum of **x** and **y** and assign the result to a new the new property **sum**.

Now paste the following into your iex session to execute your process model:

```
PS.load_process_model(model)
data = %{x: 1, y: 1}
{:ok, ppid, uid, _process_key} = PE.start_process("process name", data)
PE.execute(ppid)

```

Now, to view the state of the completed process, paste the following into your iex session:

```
PS.get_completed_process(uid)

```

and should see something like this:

```
```

We see that the new property **sum** has been added to the state of the completed process.

## User Task

A **User Task** works by having a user complete some required task. This often takes the form of a user using a GUI to examine a subset of process data and then supplying additional data. 

**Important Note**: Users interact with a BPM platfrom such as Mozart by way of user application of some kind. The user application will allow the user to find tasks which may be assigned to him. Once the user accepts responsibility for a task, the application will then provide a user interface appropriate for accomplishing the given task. 

A user task has two unique fields: **:assigned_groups** and **:inputs**.

* The **:assigned_groups** field specifies the user groups that are elibigle to complete the task. 
* The **:inputs** field is used to select which process data fields are passed to the user that will compleete the task. If no value is supplied for this field, the entire process data is passed.

### User Task example

If you are following along, open an Elixir project that has Mozart as a dependency.

```
iex -S mix

```

Now paste the following alias' into your iex session

```
 alias Mozart.ProcessEngine, as: PE
 alias Mozart.ProcessService, as: PS

```

Now we define a process model with a single service task and assign it to a variable:

```

```

We have specified that state data properties **:x** and **:y** should be available to the user that performs the task.

The user will compute the sum of **x** and **y** and assign the result to a new the new property **sum**.

Now paste the following into your iex session to execute your process model:

```
PS.clear_user_tasks()
PS.load_process_model(model)
data = %{x: 1, y: 1}
{:ok, ppid, uid, _process_key} = PE.start_process(:user_task_process_model, data)
PE.execute(ppid)

```

At this point, a user task has been opened and is available for a user to claim and complete. Now we need to find a user task that can be claimed by persons in specified groups. We can do that like this:

```
[user_task] = PS.get_user_tasks_for_groups(["admin"])

```

which gives this result:

```

```

Now, pulling the task uid from the results above, we can complete the user task like this:

```
PE.complete_user_task(ppid,  user_task.uid, %{sum: 2})

```

which will produce a result like this:

```

```

Don't be concerned regarding the **shutdown** notice. It is normal. It simply means tht the process engine shutdown becuase the process had finished.

Now we can verify that the process has completed and shows the expected value for process data:

```
PS.get_completed_process(uid)

```

and should see something like this:

```

```

We see that the new property **sum** has been added to the state of the completed process.

## Rule Task

A **Rule Task** performs its work by evaluating a rule table using process data. 

Rule tasks use [Tablex](https://hexdocs.pm/tablex/0.3.1/readme.html), an incredibly useful Elixir library for evaluating [decision tables](https://en.wikipedia.org/wiki/Decision_table).

A rule task has two unique fields: **:decision_args** and **:rule_table**.

* The **:inputs** field specifies the state data fields used to evaluate the rule table.
* The **:rule_table** field holds the Tablex table definition.

### Rule Task example

If you are following along, open an Elixir project that has Mozart as a dependency.

```
iex -S mix

```

Now paste the following alias' into your iex session

```
 alias Mozart.ProcessEngine, as: PE
 alias Mozart.ProcessService, as: PS

```

Now define a process model with a single service task and assign it to a variable:

```


```

We have specified that state data property **:income** should be available as an input field to the rule table.

The **:rule_table** property holds the Tablex table to be evaluated.

Now paste the following into your iex session to execute your process model:

```
PS.load_process_model(model)
data = %{income: 3000}
{:ok, ppid, uid, _process_key} = PE.start_process(:loan_approval, data)
PE.execute(ppid)

```

Now, to view the state of the completed process, paste the following into your iex session:

```
PS.get_completed_process(uid)

```

and should see something like this:

```

```

We see that the new property **status** with a value of **declined** has been added to the state of the completed process.

## Parallel Task

A parallel task is used to create multiple concurrent process execution paths. It does this by specifying multipple next tasks in its **multi_next** field.

If you are following along, open an Elixir project that has Mozart as a dependency.

```
iex -S mix

```

Now paste the following alias' into your iex session

```
 alias Mozart.ProcessEngine, as: PE
 alias Mozart.ProcessService, as: PS

```

Now define a process model with a parallel task and two user tasks. When the parallel task completes, the two user tasks should be opened in parallel.

```


```

We specify that state data properties **:user_task_1_input** and **:user_task_2_input** will passed to **:user_task_1** and **:user_task_2**, respectively. However, in this example we aren't going to actually complete the tasks. Hence, the property values won't actually be used.

Now paste the following into your iex session to execute your process model:

```
PS.load_process_model(model)
data = %{user_task_1_input: :input_1, user_task_2_input: :input_2}
{:ok, ppid, uid, _process_key} = PE.start_process(:parallel_process_model, data)
PE.execute(ppid)

```

Now, to view the state of the not yet complete process, paste the following into your iex session:

```
PE.get_state(ppid)

```

and should see something like this:

```


```

We see that parallel task **:parallel_user_tasks** has been completed. We also see our two user tasks have been opened in parallel, but have not yet been completed.

## Subprocess Task

A subprocess task performs its work by starting a subprocess instance as specified in its **sub_process** field.

If you are following along, open an Elixir project that has Mozart as a dependency.

```
iex -S mix

```

Now paste the following alias' into your iex session:

```
 alias Mozart.ProcessEngine, as: PE
 alias Mozart.ProcessService, as: PS

```

Now we need two process models. The first process model will call a subprocess task, wait for its completion, and then call a service task. The second process model will be called as a subprocess of the first process model.

```


```

Now paste the following into your iex session to execute your process model:

```
PS.clear_state()
PS.load_process_models(models)
data = %{value: 1}
{:ok, ppid, uid, _process_key} = PE.start_process(:call_process_model, data)
PE.execute(ppid)

```

At this point, both the processess should have completed.

```
PS.get_completed_processes()

```

and should see something like this:

```

```

We see that two processes have completed. The process named **:call_process_model** is the top level process, and the named **:service_subprocess_model** is the subprocess. As expected, the top level process state shows two completed tasks and the subprocess state shows one completed task.

## Timer Task

A **timer task** performs its work by delaying a process execution path by the duration specified in its **timer_duration** field.

If you are following along, open an Elixir project that has Mozart as a dependency.

```
iex -S mix

```

Now paste the following alias' into your iex session:

```
 alias Mozart.ProcessEngine, as: PE
 alias Mozart.ProcessService, as: PS

```

Now we need two process models. The first process model will call a subprocess task, wait for its completion, and then call a service task. The second process model will be called as a subprocess of the first process model.

```

```

Now paste the following into your iex session to execute your process model:

```
PS.clear_state()
PS.load_process_model(model)
data = %{}
{:ok, ppid, uid, _process_key} = PE.start_process(:call_timer_task, data)
PE.execute(ppid)

```

The process should take about 5 seconds to complete. Watch for logging to report **process complete**. After that, invoke the following:

```
PS.get_completed_processes()

```

and should see something like this:

```


```

Notice in the above that **execution_duration** is 5006433 microseconds, i.e. just a little over 5 seconds.

## Join Task

The **join task** is used to sychronize any number of parallel execution paths. The **inputs** field holds a list of task names that must finish before the join task can be completed.


If you are following along, open an Elixir project that has Mozart as a dependency.

```
iex -S mix

```

Now paste the following alias' into your iex session:

```
 alias Mozart.ProcessEngine, as: PE
 alias Mozart.ProcessService, as: PS

```

The process model below has a parallel task that spawns tasks **:foo** and **:bar** in parallel.

```


```

Now paste the following into your iex session to execute your process model:

```
PS.clear_state()
PS.load_process_model(model)
data = %{}
{:ok, ppid, uid, _process_key} = PE.start_process(:parallel_process_model, data)
PE.execute(ppid)

```

Due to the presense of the timer task, the process should take about 10 seconds to complete. Watch for logging to report **process complete**. After that, invoke the following:

```
PS.get_completed_processes()

```

and should see something like this:

```


```

Notice in the above that **execution_duration** is 10008138 microseconds, i.e. just a little over 10 seconds.


## Send and Receive Tasks

In this section we will demo both the **send** and **receive** tasks since they will normally be used together.

The **receive task** waits until a message has been received from a **send task** The send and receive tasks can reside in either the same of different process instances.


If you are following along, open an Elixir project that has Mozart as a dependency.

```
iex -S mix

```

Now paste the following alias' into your iex session:

```
 alias Mozart.ProcessEngine, as: PE
 alias Mozart.ProcessService, as: PS

```

The process models below contain one receiving process and one sending process.

```


```

Now paste the following into your iex session to execute, first, the receive process, and then the send process instance. We insert a 5 second delay between the two processes.

```
PS.clear_state()
PS.load_process_models(models)
data = %{}

{:ok, r_ppid, r_uid, _process_key} = PE.start_process(:process_with_receive_task, data)
PE.execute(r_ppid)
Process.sleep(5000)

{:ok, s_ppid, s_uid, _process_key} = PE.start_process(:process_with_single_send_task, data)
PE.execute(s_ppid)

```

Due to the presense of the timer task, the process should take about 10 seconds to complete. Watch for logging to report **process complete**. After that, invoke the following:

```
PS.get_completed_processes()

```

and should see something like this:

```
[


```

Notice in the above that **execution_duration** for the receive process is 5007144 microseconds, i.e. just a little over the 5 second process sleep pause.

