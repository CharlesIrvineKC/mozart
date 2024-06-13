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

{:ok, ppid, _uid, process_key} = PE.start_process(:simple_call_process_model, data)
PE.execute(ppid)

```

and we should see in our logs:

```
15:59:17.305 [info] Start process instance [simple_call_process_model][3a205a5b-07a3-4ecc-926e-0f405eddd0ac]
{:ok, #PID<0.285.0>, "3a205a5b-07a3-4ecc-926e-0f405eddd0ac",
 "272c2c9c-adcb-444d-a010-479aa68e6025"}
iex [15:58 :: 14] > PE.execute(ppid)
:ok
15:59:17.308 [info] New task instance [call_process_task][7404314e-3590-459a-a71f-458a5416966a]
15:59:17.308 [info] Start process instance [sub_process_with_one_user_task][cf66c2a2-75e9-4649-b4bd-070ca9e3746a]
15:59:17.309 [info] New task instance [user_task][106e85b5-082a-47b9-ab66-4606617efc7e]
```

Notice that two processes have been started - the top level process we explicitly started, and a subprocess. Let's use the process key to examine the state of both processes:

```
PS.get_processes_for_process_key(process_key)

```

We should see something like this:

```
iex [15:58 :: 15] > PS.get_processes_for_process_key(process_key)
[
  %Mozart.Data.ProcessState{
    uid: "3a205a5b-07a3-4ecc-926e-0f405eddd0ac",
    process_key: "272c2c9c-adcb-444d-a010-479aa68e6025",
    parent_pid: nil,
    model_name: :simple_call_process_model,
    start_time: ~U[2024-06-12 20:59:17.302851Z],
    end_time: nil,
    execute_duration: nil,
    open_tasks: %{
      "7404314e-3590-459a-a71f-458a5416966a" => %{
        complete: false,
        data: %{},
        name: :call_process_task,
        type: :sub_process,
        next: nil,
        __struct__: Mozart.Task.Subprocess,
        uid: "7404314e-3590-459a-a71f-458a5416966a",
        sub_process_model_name: :sub_process_with_one_user_task,
        sub_process_pid: #PID<0.286.0>,
        start_time: ~U[2024-06-12 20:59:17.308810Z],
        finish_time: nil,
        duration: nil,
        process_uid: "3a205a5b-07a3-4ecc-926e-0f405eddd0ac"
      }
    },
    completed_tasks: [],
    data: %{},
    complete: false
  },
  %Mozart.Data.ProcessState{
    uid: "cf66c2a2-75e9-4649-b4bd-070ca9e3746a",
    process_key: "272c2c9c-adcb-444d-a010-479aa68e6025",
    parent_pid: #PID<0.285.0>,
    model_name: :sub_process_with_one_user_task,
    start_time: ~U[2024-06-12 20:59:17.308880Z],
    end_time: nil,
    execute_duration: nil,
    open_tasks: %{
      "106e85b5-082a-47b9-ab66-4606617efc7e" => %{
        complete: false,
        function: nil,
        name: :user_task,
        type: :user,
        next: nil,
        __struct__: Mozart.Task.User,
        uid: "106e85b5-082a-47b9-ab66-4606617efc7e",
        assigned_groups: ["admin"],
        start_time: ~U[2024-06-12 20:59:17.309097Z],
        finish_time: nil,
        duration: nil,
        input_fields: nil,
        process_uid: "cf66c2a2-75e9-4649-b4bd-070ca9e3746a"
      }
    },
    completed_tasks: [],
    data: %{},
    complete: false
  }
]

```

As we expected, we see that there are two processes, each having one open task. The high level process has an open subprocess task. The subprocess has a user task open.