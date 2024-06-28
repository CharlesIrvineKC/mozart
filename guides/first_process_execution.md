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
            inputs: [:x],
            function: fn data -> Map.put(data, :x, data.x + 1) end
          }
        ],
        initial_task: :service_task
    }
```

The process model definition is pretty simple. It uses two Mozart structures: `Mozart.Task.Service` and `Mozart.Data.ProcessModel`. The name of the process model is **:process_with_single_service_task**. It has just one service task which is named **:service_task**, and this task is the **initial_task** that will be opened upon upon process execution. The service task does not specify a next task so the process will complete after this task is completed.

## Load the Process Model into repository

Now let's load this process model into the process model repository, which is implemented by (`Mozart.ProcessService`). First, let's paste a few aliases into our iex session:

```elixir
alias Mozart.ProcessEngine, as: PE
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
            inputs: [:x],
            function: fn data -> Map.put(data, :x, data.x + 1) end
          }
        ],
        initial_task: :service_task
    }
PS.load_process_model(process_model)
PS.get_process_model(:process_with_single_service_task)

```

First, we assigned a process model to a variable.
Secondly, we loaded the process definition into our repository.
Finally, we pulled the process model from the repository as verification. At the very bottom of the output, you should see the result of calling **get_process_model(:process_with_single_service_task)**:


```
iex [12:52 :: 8] > PS.get_process_model(:process_with_single_service_task)
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
{:ok, pid, uid, _process_key} = 
  PE.start_process(:process_with_single_service_task, %{x: 0})
PE.execute(pid)

```

First, we started a process using `Mozart.ProcessEngin.start_process/2`. We passed it the name of the process model to be executed and some initial data required for process execution. The function returns a tuple with three values: 

* The **pid** of the resulting process engine.
* The **uid** of the process instance. Every process execution will need a unique identifier. You will see how this is used going forward.
* Finally, a **process_key** is returned. Process modes are hierarchial, meaning they can be composed of multiple, nested subprocesses. The top level business process and all of its subprocesses will share the same *process_key*.

After creating the process engine instance, we then call `Mozart.ProcessEngine.execute/1` which causes the process engine to start completing any tasks that are ready to be completed. After calling the **execute** function, you should see something like:

```
iex [12:22 :: 12] > {:ok, pid, uid, _process_key} = PE.start_process(:process_with_single_service_task, %{x: 0})
12:27:40.898 [info] Start process instance [process_with_single_service_task][0800de9a-8ec5-4906-bf50-bd09321f5982]
{:ok, #PID<0.277.0>, "0800de9a-8ec5-4906-bf50-bd09321f5982", "0800de9a-8ec5-4906-bf50-bd09321f1234"}
iex [12:22 :: 13] > PE.execute(pid)
:ok
12:27:40.899 [info] New task instance [service_task][da19b03a-009a-42aa-948c-4ad139d0fe66]
12:27:40.899 [info] Complete service task [service_task[da19b03a-009a-42aa-948c-4ad139d0fe66]
12:27:40.899 [info] Process complete [process_with_single_service_task][0800de9a-8ec5-4906-bf50-bd09321f5982]
```

The logs show that:

1. A new process engine was created.
1. A new service task was opened.
1. The service task completed.
1. And finally the process engine completed executing the process model.

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
  parent_pid: nil,
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

