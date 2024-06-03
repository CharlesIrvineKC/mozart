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

A parallel task `Mozart.Task.Parallel` is used to multiple concurrent process execution paths. 

If you are following along, open an Elixir project that has Mozart as a dependency.

```
iex -S mix

```

Now paste the following alias' into your iex session

```
 alias Mozart.Data.ProcessModel
 alias Mozart.Task.Parallel
 alias Mozart.Task.User
 alias Mozart.ProcessEngine, as: PE
 alias Mozart.ProcessService, as: PS

```

Now define a process model with a parallel task and two user tasks. When the parallel task completes, the two user tasks should be opened in parallel.

```
model = %ProcessModel{
        name: :parallel_process_model,
        tasks: [
          %Parallel{
            name: :parallel_user_tasks,
            multi_next: [:user_task_1, :user_task_2]
          },
          %User{
            name: :user_task_1,
            input_fields: [:user_task_1_input],
            assigned_groups: ["admin"]
          },
          %User{
            name: :user_task_2,
            input_fields: [:user_task_2_input],
            assigned_groups: ["admin"]
          }
        ],
        initial_task: :parallel_user_tasks
      }

```

We specify that state data properties **:user_task_1_input** and **:user_task_2_input** will passed to **:user_task_1** and **:user_task_2**, respectively. However, in this example we aren't going to actually complete the tasks. Hence, the property values won't actually be used.

Now paste the following into your iex session to execute your process model:

```
PS.load_process_model(model)
data = %{user_task_1_input: :input_1, user_task_2_input: :input_2}
{:ok, ppid, uid} = PE.start_process(:parallel_process_model, data)
PE.execute(ppid)

```

Now, to view the state of the not yet complete process, paste the following into your iex session:

```
PE.get_state(ppid)

```

and should see something like this:

```
iex [10:32 :: 11] > PE.get_state(ppid)
%Mozart.Data.ProcessState{
  uid: "f7bffb0d-a66e-4381-bcba-01b9f06ac68b",
  parent: nil,
  model_name: :parallel_process_model,
  start_time: ~U[2024-06-01 15:33:23.663777Z],
  end_time: nil,
  execute_duration: nil,
  open_tasks: %{
    "0fe80867-0a8c-4721-ad57-838dbb0901ac" => %{
      complete: false,
      function: nil,
      name: :user_task_2,
      type: :user,
      next: nil,
      __struct__: Mozart.Task.User,
      uid: "0fe80867-0a8c-4721-ad57-838dbb0901ac",
      assigned_groups: ["admin"],
      input_fields: [:user_task_2_input],
      process_uid: "f7bffb0d-a66e-4381-bcba-01b9f06ac68b"
    },
    "12925277-c6e0-4310-a87b-8945573017ba" => %{
      complete: false,
      function: nil,
      name: :user_task_1,
      type: :user,
      next: nil,
      __struct__: Mozart.Task.User,
      uid: "12925277-c6e0-4310-a87b-8945573017ba",
      assigned_groups: ["admin"],
      input_fields: [:user_task_1_input],
      process_uid: "f7bffb0d-a66e-4381-bcba-01b9f06ac68b"
    }
  },
  completed_tasks: [
    %{
      function: nil,
      name: :parallel_user_tasks,
      type: :parallel,
      __struct__: Mozart.Task.Parallel,
      uid: "aa0108cf-2f2c-4700-b97a-49ca7b002c18",
      multi_next: [:user_task_1, :user_task_2],
      sub_process: nil,
      process_uid: "f7bffb0d-a66e-4381-bcba-01b9f06ac68b"
    }
  ],
  data: %{user_task_1_input: :input_1, user_task_2_input: :input_2},
  complete: false
}

```

We see that parallel task **:parallel_user_tasks** has been completed. We also see our two user tasks have been opened in parallel, but have not yet been completed.

## Subprocess Task

If you are following along, open an Elixir project that has Mozart as a dependency.

```
iex -S mix

```

Now paste the following alias' into your iex session:

```
 alias Mozart.Data.ProcessModel
 alias Mozart.Task.Subprocess
 alias Mozart.Task.Service
 alias Mozart.ProcessEngine, as: PE
 alias Mozart.ProcessService, as: PS

```

Now we need two process models. The first process model will call a subprocess task, wait for its completion, and then call a service task. The second process model will be called as a subprocess of the first process model.

```
models = 
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

```

Now paste the following into your iex session to execute your process model:

```
PS.clear_state()
PS.load_process_models(models)
data = %{value: 1}
{:ok, ppid, uid} = PE.start_process(:call_process_model, data)
PE.execute(ppid)

```

At this point, both the processess should have completed.

```
PS.get_completed_processes()

```

and should see something like this:

```
iex [12:30 :: 12] > PS.get_completed_processes()
[
  %Mozart.Data.ProcessState{
    uid: "0a04f109-505b-4059-a5e2-0980c3229ce2",
    parent: #PID<0.299.0>,
    model_name: :service_subprocess_model,
    start_time: ~U[2024-06-02 17:30:33.946285Z],
    end_time: ~U[2024-06-02 17:30:33.946645Z],
    execute_duration: 360,
    open_tasks: %{},
    completed_tasks: [
      %{
        function: #Function<42.105768164/1 in :erl_eval.expr/6>,
        name: :service_task,
        type: :service,
        next: nil,
        __struct__: Mozart.Task.Service,
        uid: "c4466a99-6f07-465c-802a-2b8836499940",
        input_fields: nil,
        process_uid: "0a04f109-505b-4059-a5e2-0980c3229ce2"
      }
    ],
    data: %{value: 1, subprocess_data: "subprocess data"},
    complete: true
  },
  %Mozart.Data.ProcessState{
    uid: "83769669-388d-490a-a326-cd5c3c684361",
    parent: nil,
    model_name: :call_process_model,
    start_time: ~U[2024-06-02 17:30:33.939824Z],
    end_time: ~U[2024-06-02 17:30:33.947097Z],
    execute_duration: 7273,
    open_tasks: %{},
    completed_tasks: [
      %{
        function: #Function<42.105768164/1 in :erl_eval.expr/6>,
        name: :service_task1,
        type: :service,
        next: nil,
        __struct__: Mozart.Task.Service,
        uid: "692c0af0-b5f5-4474-a478-6de3cdd84ec8",
        input_fields: nil,
        process_uid: "83769669-388d-490a-a326-cd5c3c684361"
      },
      %{
        complete: true,
        data: %{},
        function: nil,
        name: :call_process_task,
        type: :sub_process,
        next: :service_task1,
        __struct__: Mozart.Task.Subprocess,
        uid: "ee4211a0-ee8e-4b6d-992d-80121566bd41",
        sub_process: :service_subprocess_model,
        process_uid: "83769669-388d-490a-a326-cd5c3c684361",
        completed_sub_tasks: []
      }
    ],
    data: %{value: 2, subprocess_data: "subprocess data"},
    complete: true
  }
]
```

We see that two processes have completed. The process named **:call_process_model** is the top level process, and the named **:service_subprocess_model** is the subprocess. As expected, the top level process state shows two completed tasks and the subprocess state shows one completed task.

## Timer Task

If you are following along, open an Elixir project that has Mozart as a dependency.

```
iex -S mix

```

Now paste the following alias' into your iex session:

```
 alias Mozart.Data.ProcessModel
 alias Mozart.Task.Timer
 alias Mozart.ProcessEngine, as: PE
 alias Mozart.ProcessService, as: PS

```

Now we need two process models. The first process model will call a subprocess task, wait for its completion, and then call a service task. The second process model will be called as a subprocess of the first process model.

```
model = 
    %ProcessModel{
        name: :call_timer_task,
        tasks: [
          %Timer{
            name: :wait_5_seconds,
            timer_duration: 5000
          },
        ],
        initial_task: :wait_5_seconds
      }

```

Now paste the following into your iex session to execute your process model:

```
PS.clear_state()
PS.load_process_model(model)
data = %{}
{:ok, ppid, uid} = PE.start_process(:call_timer_task, data)
PE.execute(ppid)

```

The process should take about 5 seconds to complete. Watch for logging to report **process complete**. After that, invoke the following:

```
PS.get_completed_processes()

```

and should see something like this:

```
[
  %Mozart.Data.ProcessState{
    uid: "67e7f64e-7a06-4622-9b9e-1d89b552ae3b",
    parent: nil,
    model_name: :call_timer_task,
    start_time: ~U[2024-06-02 18:07:18.670993Z],
    end_time: ~U[2024-06-02 18:07:23.677426Z],
    execute_duration: 5006433,
    open_tasks: %{},
    completed_tasks: [
      %{
        function: nil,
        name: :wait_5_seconds,
        type: :timer,
        next: nil,
        expired: true,
        __struct__: Mozart.Task.Timer,
        uid: "eacaaf01-37b9-43ef-be81-d2ccb8802084",
        timer_duration: 5000,
        process_uid: "67e7f64e-7a06-4622-9b9e-1d89b552ae3b"
      }
    ],
    data: %{},
    complete: true
  }
]

```

Notice in the above that **execution_duration** is 5006433 microseconds, i.e. just a little over 5 seconds.

## Join Task


If you are following along, open an Elixir project that has Mozart as a dependency.

```
iex -S mix

```

Now paste the following alias' into your iex session:

```
 alias Mozart.Data.ProcessModel
 alias Mozart.Task.Join
 alias Mozart.Task.Parallel
 alias Mozart.ProcessEngine, as: PE
 alias Mozart.ProcessService, as: PS

```

The process model below has a parallel task that spawns tasks **:foo** and **:bar** in parallel.

```
model = 
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

```

Now paste the following into your iex session to execute your process model:

```
PS.clear_state()
PS.load_process_model(model)
data = %{}
{:ok, ppid, uid} = PE.start_process(:call_timer_task, data)
PE.execute(ppid)

```

The process should take about 5 seconds to complete. Watch for logging to report **process complete**. After that, invoke the following:

```
PS.get_completed_processes()

```

and should see something like this:

```
[
  %Mozart.Data.ProcessState{
    uid: "67e7f64e-7a06-4622-9b9e-1d89b552ae3b",
    parent: nil,
    model_name: :call_timer_task,
    start_time: ~U[2024-06-02 18:07:18.670993Z],
    end_time: ~U[2024-06-02 18:07:23.677426Z],
    execute_duration: 5006433,
    open_tasks: %{},
    completed_tasks: [
      %{
        function: nil,
        name: :wait_5_seconds,
        type: :timer,
        next: nil,
        expired: true,
        __struct__: Mozart.Task.Timer,
        uid: "eacaaf01-37b9-43ef-be81-d2ccb8802084",
        timer_duration: 5000,
        process_uid: "67e7f64e-7a06-4622-9b9e-1d89b552ae3b"
      }
    ],
    data: %{},
    complete: true
  }
]

```

Notice in the above that **execution_duration** is 5006433 microseconds, i.e. just a little over 5 seconds.


## Send Task
## Receive Task

