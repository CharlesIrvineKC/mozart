# Mozart Event Types

Currently, there is just one event type as described below. This document will be updated as addtional event types are implemented.

## Task Exit Event

A **Task Exit Event** (`Mozart.Event.TaskExit`) allows a process execution to exit an open task in response to an external event (a Phoenix.PubSub event). When the task exits in this way, process execution will follow an alternate execution path as specified the the *task exit event*.

The *task exit event* is implemented by a struct with the following fields:

* A **name** field with uniquely identifies the event within the scope of the containing process model.
* Optionally, a **function** field can be used to alter the process data when the event is handled.
* **message_selector** field requires a function specification used to select Phoenix.PubSub events.
* The **exit_task** field specifies the name of the task that would exit in response to the event.
* The **next** field specifies the name of the next task, if any, that should be opened in response to the event.
* Finally, a **type** field that will default to  **:task_exit** for this event type.

## Task Exit Event Example

If you are following along, open an Elixir project that has Mozart as a dependency.

```
iex -S mix

```

Now paste the following alias' into your iex session

```
 alias Mozart.Data.ProcessModel
 alias Mozart.ProcessEngine, as: PE
 alias Mozart.ProcessService, as: PS
 alias Mozart.Task.Service
 alias Mozart.Task.User
 alias Mozart.Task.Subprocess
 alias Mozart.Event.TaskExit

```

Now we define two process models - one top level model and one subprocess model. We specify a **TaskExit** event whose occurence will cause the subprocess to exit and a new service task to be opened.

Go ahead and paste it into your iex session:

```
models = [
      %ProcessModel{
        name: :simple_call_process_model,
        tasks: [
          %Subprocess{
            name: :call_process_task,
            sub_process_model_name: :sub_process_with_one_user_task
          },
          %Service{
            name: :service_after_task_exit,
            function: fn data -> Map.put(data, :service_after_task_exit, true) end
          }
        ],
        events: [
          %TaskExit{
            name: :exit_sub_process,
            exit_task: :call_process_task,
            message_selector: fn msg ->
              case msg do
                :exit_user_task -> true
                _ -> nil
              end
            end,
            next: :service_after_task_exit
          }
        ],
        initial_task: :call_process_task
      },
    %ProcessModel{
      name: :sub_process_with_one_user_task,
      tasks: [
        %User{
          name: :user_task,
          assigned_groups: ["admin"]
        }
      ],
      initial_task: :user_task
    }
  ]

```

Now let's load the process models, and then start and execute the process top level process model:

```
PS.clear_state()
PS.load_process_models(models)
data = %{}

{:ok, ppid, _uid} = PE.start_process(:simple_call_process_model, data)
PE.execute(ppid)

```

Now, let's look at the state of the top level process:

```
PE.get_state(ppid)

```

We should see something like this:

```
iex [15:38 :: 24] > PE.get_state(ppid)
%Mozart.Data.ProcessState{
  uid: "9e0c232f-d22b-43a0-8a1a-cea0aca356d1",
  parent_uid: nil,
  model_name: :simple_call_process_model,
  start_time: ~U[2024-06-09 20:42:40.936413Z],
  end_time: nil,
  execute_duration: nil,
  open_tasks: %{
    "db1706e9-6cf7-4b4e-b717-284cef723db4" => %{
      complete: false,
      data: %{},
      name: :call_process_task,
      type: :sub_process,
      next: nil,
      __struct__: Mozart.Task.Subprocess,
      uid: "db1706e9-6cf7-4b4e-b717-284cef723db4",
      sub_process_model_name: :sub_process_with_one_user_task,
      sub_process_pid: #PID<0.291.0>,
      start_time: ~U[2024-06-09 20:42:40.939348Z],
      finish_time: nil,
      duration: nil,
      process_uid: "9e0c232f-d22b-43a0-8a1a-cea0aca356d1"
    }
  },
  completed_tasks: [],
  data: %{},
  complete: false
}


```