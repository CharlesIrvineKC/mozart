# Mozart Task Types

This guide will describe and give examples of each of the Mozart task types. We will use an [**example file**](https://github.com/CharlesIrvineKC/mozart/blob/main/lib/mozart/examples/examples.ex) from the Mozart GitHub repository. Copy it to your repository if you would like to follow along.

Each example consists of two functions. One returns a list of process models. The other function, whose name starts with **run_**, is used to execute the process model in a process engine instance.

Each **run_** function will output the state of the completed process for you to inspect.

## Properties Common to All Task Types

All of the task types have the following properties:
* **name**: an atome specifying the name of the task. Must be unique within the scope of the parent process model.
* **next**: the name of the task that should be opened after completion of the current task. Exception: The task type `Mozart.Task.Paralled` doesn't have a next field. Instead, it has a multi_next field, which specifies next tasks that should be opened in parallel.
* **uid**: When a task is opened (instantiated) it is assigned a unique identifier, i.e. its *uid*.
* **type**: Specifies the type of the task. This value is defaulted automatically for each task type.

## Service Task

A **Service Task** (`Mozart.Task.Service`) performs its work by calling an Elixir function. This function could perform a computation, call an external JSON service, retrieve data from a database, etc.

A service task has three unique fields: **:function**, **:input_fields** and **:data**.

* The **:function** field specifies the function that the service task should apply for the purpose of returning output data into the process state.
* The **:input_fields** field is used to select which process data fields are passed to the task's function. If no value is supplied for this field, the entire process data is passed.
* The **:data** field is populated with the data returned to process data.

### Service Task example

If you are following along, open your project in iex:

```
iex -S mix

```

Now import the Example module:

```
import Mozart.Examples.Example

```

Now invoke the **run_single_service_task/0** function:

```
run_single_service_task()

```

The result should be something like:

```
service process state: %Mozart.Data.ProcessState{
  uid: "2f577410-af1a-498a-9d9d-3935dc9eea55",
  parent: nil,
  model_name: :process_with_single_service_task,
  start_time: ~U[2024-05-29 19:07:20.445452Z],
  end_time: ~U[2024-05-29 19:07:20.448849Z],
  execute_duration: 3397,
  open_tasks: %{},
  completed_tasks: [
    %{
      data: %{},
      function: #Function<11.76693851/1 in Mozart.Examples.Example.single_service_task/0>,
      name: :service_task,
      type: :service,
      next: nil,
      __struct__: Mozart.Task.Service,
      uid: "d94ee606-13e6-4f80-8e74-3cda4672e323",
      input_fields: nil,
      process_uid: "2f577410-af1a-498a-9d9d-3935dc9eea55"
    }
  ],
  data: %{value: 1},
  complete: true
}
```

Note that the service task correctly incremented the **value** property by 1.

## User Task
## Decision Task
## Parallel Task
## Subprocess Task
## Timer Task
## Join Task
## Send Task
## Receive Task

