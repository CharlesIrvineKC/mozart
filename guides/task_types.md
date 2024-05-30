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
 alias Mozart.ProcessModelService, as: PMS
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
PMS.load_process_model(model)
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
## Decision Task
## Parallel Task
## Subprocess Task
## Timer Task
## Join Task
## Send Task
## Receive Task

