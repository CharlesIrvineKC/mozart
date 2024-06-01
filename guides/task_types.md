# Mozart Task Types

## Properties Common to All Task Types

All of the task types have the following properties:
* **name**: an atome specifying the name of the task. Must be unique within the scope of the parent process model.
* **next**: the name of the task that should be opened after completion of the current task. Exception: The task type `Mozart.Task.Paralled` doesn't have a next field. Instead, it has a multi_next field, which specifies next tasks that should be opened in parallel.
* **uid**: When a task is opened (instantiated) it is assigned a unique identifier, i.e. its *uid*.
* **type**: Specifies the type of the task. This value is defaulted automatically for each task type.

## Service Task

A **Service Task** (`Mozart.Task.Service`) performs its work by calling an Elixir function. This function could perform a computation, call an external JSON service, retrieve data from a database, etc.

A service task has two unique fields: **:function** and **:input_fields**.

* The **:function** field specifies the function that the service task should apply for the purpose of returning output data into the process state.
* The **:input_fields** field is used to select which process data fields are passed to the task's function. If no value is supplied for this field, the entire process data is passed.

### Service Task example

If you are following along, open an Elixir project that has Mozart as a dependency.

```
iex -S mix

```

Now paste the following alias' into your iex session

```
 alias Mozart.Data.ProcessModel
 alias Mozart.Task.Service
 alias Mozart.ProcessEngine, as: PE
 alias Mozart.ProcessService, as: PS

```

Now define a process model with a single service task and assign it to a variable:

```
model = %ProcessModel{
    name: :process_with_single_service_task,
    tasks: [
      %Service{
        name: :service_task,
        input_fields: [:x, :y],
        function: fn data -> Map.put(data, :sum, data.x + data.y) end
      }
    ],
    initial_task: :service_task
}

```

We have specified that state data properties **:x** and **:y** should be available to the task's function. 

The task function will take the sum of **x** and **y** and assign the result to a new the new property **sum**.

Now paste the following into your iex session to execute your process model:

```
PS.load_process_model(model)
data = %{x: 1, y: 1}
{:ok, ppid, uid} = PE.start_process(:process_with_single_service_task, data)
PE.execute(ppid)

```

Now, to view the state of the completed process, paste the following into your iex session:

```
PS.get_completed_process(uid)

```

and should see something like this:

```
iex [12:21 :: 11] > PS.get_completed_process(uid)
%Mozart.Data.ProcessState{
  uid: "53d0220b-4e0c-42bb-9154-7e4aeff83837",
  parent: nil,
  model_name: :process_with_single_service_task,
  start_time: ~U[2024-05-30 17:22:49.156516Z],
  end_time: ~U[2024-05-30 17:22:49.161447Z],
  execute_duration: 4931,
  open_tasks: %{},
  completed_tasks: [
    %{
      function: #Function<42.105768164/1 in :erl_eval.expr/6>,
      name: :service_task,
      type: :service,
      next: nil,
      __struct__: Mozart.Task.Service,
      uid: "443319db-9cef-47c0-9366-9b95ec1fa42b",
      input_fields: [:x, :y],
      process_uid: "53d0220b-4e0c-42bb-9154-7e4aeff83837"
    }
  ],
  data: %{sum: 2, y: 1, x: 1},
  complete: true
}
```

We see that the new property **sum** has been added to the state of the completed process.

## User Task

A **User Task** (`Mozart.Task.User`) works by having a user complete some required task. This often takes the form of a user using a GUI to examine a subset of process data and then supplying additional data. 

**Important Note**: Users interact with a BPM platfrom such as Mozart by way of user application of some kind. The user application will allow the user to find tasks which may be assigned to him. Once the user accepts responsibility for a task, the application will then provide a user interface appropriate for accomplishing the given task. 

A user task has two unique fields: **:assigned_groups** and **:input_fields**.

* The **:assigned_groups** field specifies the user groups that are elibigle to complete the task. 
* The **:input_fields** field is used to select which process data fields are passed to the user that will compleete the task. If no value is supplied for this field, the entire process data is passed.

### User Task example

If you are following along, open an Elixir project that has Mozart as a dependency.

```
iex -S mix

```

Now paste the following alias' into your iex session

```
 alias Mozart.Data.ProcessModel
 alias Mozart.Task.User
 alias Mozart.ProcessEngine, as: PE
 alias Mozart.ProcessService, as: PS

```

Now we define a process model with a single service task and assign it to a variable:

```
model = %ProcessModel{
      name: :user_task_process_model,
      tasks: [
        %User{
          name: :user_task,
          input_fields: [:x, :y],
          assigned_groups: ["admin"]
        }
      ],
      initial_task: :user_task
  }

```

We have specified that state data properties **:x** and **:y** should be available to the user that performs the task.

The user will compute the sum of **x** and **y** and assign the result to a new the new property **sum**.

Now paste the following into your iex session to execute your process model:

```
PS.clear_user_tasks()
PS.load_process_model(model)
data = %{x: 1, y: 1}
{:ok, ppid, uid} = PE.start_process(:user_task_process_model, data)
PE.execute(ppid)

```

At this point, a user task has been opened and is available for a user to claim and complete. Now we need to find a user task that can be claimed by persons in specified groups. We can do that like this:

```
[user_task] = PS.get_user_tasks_for_groups(["admin"])

```

which gives this result:

```
13:29:25.959 [info] New task instance [user_task][09fe2c87-d2c8-401b-a4df-83a7edab987d]
iex [13:28 :: 11] > PS.get_user_tasks_for_groups(["admin"])
[
  %{
    complete: false,
    data: %{y: 1, x: 1},
    function: nil,
    name: :user_task,
    type: :user,
    next: nil,
    __struct__: Mozart.Task.User,
    uid: "09fe2c87-d2c8-401b-a4df-83a7edab987d",
    assigned_groups: ["admin"],
    input_fields: [:x, :y],
    process_uid: "69b51421-cc10-45d7-8ca2-70c0e232cb82"
  }
]
```

Now, pulling the task uid from the results above, we can complete the user task like this:

```
PE.complete_user_task(ppid,  user_task.uid, %{sum: 2})

```

which will produce a result like this:

```
iex [16:54 :: 12] > PE.complete_user_task(ppid,  user_task.uid, %{sum: 2})
16:56:11.417 [info] Complete user task [user_task][9b88be91-3b99-4e9c-b362-0f0dc5fb604c]
16:56:11.417 [info] Process complete [user_task_process_model][d7bed372-94c4-477a-be0a-dcc7417c6e60]
** (exit) exited in: GenServer.call(#PID<0.273.0>, {:complete_user_task, "9b88be91-3b99-4e9c-b362-0f0dc5fb604c", %{sum: 2}}, 5000)
    ** (EXIT) shutdown
    (elixir 1.16.2) lib/gen_server.ex:1114: GenServer.call/3
    iex:12: (file)
```

Don't be concerned regarding the **shutdown** notice. It is normal. It simply means tht the process engine shutdown becuase the process had finished.

Now we can verify that the process has completed and shows the expected value for process data:

```
PS.get_completed_process(uid)

```

and should see something like this:

```
iex [13:28 :: 12] > PS.get_completed_process(uid)
%Mozart.Data.ProcessState{
  uid: "69b51421-cc10-45d7-8ca2-70c0e232cb82",
  parent: nil,
  model_name: :user_task_process_model,
  start_time: ~U[2024-05-30 18:29:25.954801Z],
  end_time: ~U[2024-05-30 21:35:58.017106Z],
  execute_duration: 11192062305,
  open_tasks: %{},
  completed_tasks: [
    %{
      complete: false,
      function: nil,
      name: :user_task,
      type: :user,
      next: nil,
      __struct__: Mozart.Task.User,
      uid: "09fe2c87-d2c8-401b-a4df-83a7edab987d",
      assigned_groups: ["admin"],
      input_fields: [:x, :y],
      process_uid: "69b51421-cc10-45d7-8ca2-70c0e232cb82"
    }
  ],
  data: %{sum: 3, y: 1, x: 1},
  complete: true
}
```

We see that the new property **sum** has been added to the state of the completed process.

## Rule Task

A **Rule Task** (`Mozart.Task.Rule`) performs its work by evaluating a rule table using process data. 

Rule tasks use [Tablex](https://hexdocs.pm/tablex/0.3.1/readme.html), an incredibly useful Elixir library for evaluating [decision tables](https://en.wikipedia.org/wiki/Decision_table).

A rule task has two unique fields: **:decision_args** and **:rule_table**.

* The **:input_fields** field specifies the state data fields used to evaluate the rule table.
* The **:rule_table** field holds the Tablex table definition.

### Rule Task example

If you are following along, open an Elixir project that has Mozart as a dependency.

```
iex -S mix

```

Now paste the following alias' into your iex session

```
 alias Mozart.Data.ProcessModel
 alias Mozart.Task.Rule
 alias Mozart.ProcessEngine, as: PE
 alias Mozart.ProcessService, as: PS

```

Now define a process model with a single service task and assign it to a variable:

```
model = %ProcessModel{
    name: :loan_approval,
    tasks: [
      %Rule{
        name: :loan_decision,
        input_fields: [:income],
        rule_table:
          Tablex.new("""
          F     income      || status
          1     > 50000     || approved
          2     <= 49999    || declined
          """)
      }
    ],
    initial_task: :loan_decision
}

```

We have specified that state data property **:income** should be available as an input field to the rule table.

The **:rule_table** property holds the Tablex table to be evaluated.

Now paste the following into your iex session to execute your process model:

```
PS.load_process_model(model)
data = %{income: 3000}
{:ok, ppid, uid} = PE.start_process(:loan_approval, data)
PE.execute(ppid)

```

Now, to view the state of the completed process, paste the following into your iex session:

```
PS.get_completed_process(uid)

```

and should see something like this:

```
iex [20:45 :: 11] > PS.get_completed_process(uid)
%Mozart.Data.ProcessState{
  uid: "b79fe224-52b9-4457-b885-1234c47c0eb3",
  parent: nil,
  model_name: :loan_approval,
  start_time: ~U[2024-06-01 01:45:57.687401Z],
  end_time: ~U[2024-06-01 01:45:57.695101Z],
  execute_duration: 7700,
  open_tasks: %{},
  completed_tasks: [
    %{
      name: :loan_decision,
      type: :rule,
      next: nil,
      __struct__: Mozart.Task.Rule,
      uid: "a045ccfe-21d1-410f-aa87-6e020017e48d",
      input_fields: [:income],
      rule_table: %Tablex.Table{
        hit_policy: :first_hit,
        inputs: [
          %Tablex.Variable{
            name: :income,
            label: "income",
            desc: nil,
            type: :undefined,
            path: []
          }
        ],
        outputs: [
          %Tablex.Variable{
            name: :status,
            label: "status",
            desc: nil,
            type: :undefined,
            path: []
          }
        ],
        rules: [
          [1, {:input, [>: 50000]}, {:output, ["approved"]}],
          [2, {:input, [<=: 49999]}, {:output, ["declined"]}]
        ],
        valid?: :undefined,
        table_dir: :h
      },
      process_uid: "b79fe224-52b9-4457-b885-1234c47c0eb3"
    }
  ],
  data: %{status: "declined", income: 3000},
  complete: true
}
```

We see that the new property **status** with a value of **declined** has been added to the state of the completed process.

## Parallel Task
## Subprocess Task
## Timer Task
## Join Task
## Send Task
## Receive Task

