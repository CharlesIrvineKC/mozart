# First Process Execution

Now we will put together what we've lerned so far to execute a process model. 

## To Follow Along..

To follow along create a new Elxir project and then add Mozart as a dependency. Your dependency should look like this:

```elixir
  defp deps do
    [
      {:mozart, "~> 0.1"}
    ]
  end
```

## Construct the Process Model

First, let us construct a simple process model that will have a single service task. The service task will simply add one to a data property. Here is the process model:

```elixir
    %ProcessModel{
        name: :process_with_single_service_task,
        tasks: [
          %Service{
            name: :service_task,
            input_fields: [:x],
            function: fn data -> Map.put(data, :x, data.x + 1) end
          }
        ],
        initial_task: :service_task
    }
```

The process model definition is pretty simple. It uses two Mozart structures: `Mozart.Task.Service` and `Mozart.Data.ProcessModel`. The name of the process model is **:process_with_single_service_task**. It has just one service task which is named **:service_task**, and this task is the **initial_task** that will be opened upon upon process execution. The service task does not specify a next task so the process will complete after this task is completed.

## Load the Process Model into repository

Now let's load this process model into the process model repository (`Mozart.ProcessModelService`). First, let's paste a few aliases into our iex session:

```elixir
alias Mozart.ProcessEngine, as: PE
alias Mozart.ProcessModelService, as: PMS
alias Mozart.ProcessService, as: PS
alias Mozart.Task.Service
alias Mozart.Data.ProcessModel

```

Now we are ready to load our process model into the repository. Copy the following into your iex session:

```elixir
process_model = 
    %ProcessModel{
        name: :process_with_single_service_task,
        tasks: [
          %Service{
            name: :service_task,
            input_fields: [:x],
            function: fn data -> Map.put(data, :x, data.x + 1) end
          }
        ],
        initial_task: :service_task
    }
PMS.load_process_model(process_model)
PMS.get_process_model(:process_with_single_service_task)

```

First, we assigned a process model to a variable.
Secondly, we loaded the process definition into our repository.
Finally, we pulled the process model from the repository as verification. At the very bottom of the output, you should see the result of calling **get_process_model(:process_with_single_service_task)**:


```
iex [12:52 :: 8] > PMS.get_process_model(:process_with_single_service_task)
%Mozart.Data.ProcessModel{
  name: :process_with_single_service_task,
  tasks: [
    %Mozart.Task.Service{
      name: :service_task,
      function: #Function<42.105768164/1 in :erl_eval.expr/6>,
      next: nil,
      uid: nil,
      data: %{},
      type: :service
    }
  ],
  initial_task: :service_task
}
```

## Start a Process Engine and Execute the Process Model

Now let us start a process engine, initializing it with our process model and some data. Then we call the function that will invoke process execution. Copy the following into your iex session:

```elixir
{:ok, pid, uid} = PE.start_process(:process_with_single_service_task, %{x: 0})
PE.execute(pid)

```

You should see something like:

```
iex [12:22 :: 12] > {:ok, pid, uid} = PE.start_process(:process_with_single_service_task, %{x: 0})
12:27:40.898 [info] Start process instance [process_with_single_service_task][0800de9a-8ec5-4906-bf50-bd09321f5982]
{:ok, #PID<0.277.0>, "0800de9a-8ec5-4906-bf50-bd09321f5982"}
iex [12:22 :: 13] > PE.execute(pid)
:ok
12:27:40.899 [info] New task instance [service_task][da19b03a-009a-42aa-948c-4ad139d0fe66]
12:27:40.899 [info] Complete service task [service_task[da19b03a-009a-42aa-948c-4ad139d0fe66]
12:27:40.899 [info] Process complete [process_with_single_service_task][0800de9a-8ec5-4906-bf50-bd09321f5982]
```

We created an instance of a process engine (`Mozart.ProcessEngine`) specifying the name of the process model to run and some initial data. Notice that the data includes the property **x** that our service task will use to do its computation.

## Verify the Results

Let's verify the results of our process model execution. Copy the following into your iex session:

```elixir
PS.get_completed_process(uid)

```

and you should see:

```elixir
iex [12:22 :: 14] > PS.get_completed_process(uid)
%Mozart.Data.ProcessState{
  uid: "0800de9a-8ec5-4906-bf50-bd09321f5982",
  parent: nil,
  model_name: :process_with_single_service_task,
  start_time: ~U[2024-05-28 17:27:40.898328Z],
  end_time: ~U[2024-05-28 17:27:40.899505Z],
  execute_duration: 1177,
  open_tasks: %{},
  completed_tasks: [
    %{
      data: %{},
      function: #Function<42.105768164/1 in :erl_eval.expr/6>,
      name: :service_task,
      type: :service,
      next: nil,
      __struct__: Mozart.Task.Service,
      uid: "da19b03a-009a-42aa-948c-4ad139d0fe66",
      process_uid: "0800de9a-8ec5-4906-bf50-bd09321f5982"
    }
  ],
  data: %{x: 1},
  complete: true
}
```

We see the start and end times of process execution as well as the execution duration of 1177 microseconds (or 1.177 milliseconds). We see that tasks that were completed. And, finally, we see that the service task has done its job of adding 1 to the value of **x**.

