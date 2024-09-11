# Mozart Event Types

Currently, there is just one event type has been implemented (see below). This document will be updated as addtional event types are implemented.

## Task Exit Event

A **Task Exit Event** allows a process execution to exit an open task in response to an external event (a Phoenix.PubSub event). When the task exits in this way, process execution will follow an alternate execution path as specified the the *task exit event*.

The *task exit event* is implemented by the **defevent/3** DSL function which takes the following arguments:

  * the name of the event
  * **process**: the name of the process that the event will act upon
  * **exit_task**: the name of the task to be exited
  * **selector**: a function that matches on the target event
  * **do**: one or more tasks to be executed when the target task is exited.
  
  Here is an example:

  ```elixir
  defevent "exit loan decision 1",
    process: "exit a user task 1",
    exit_task: "user task 1",
    selector: &BpmAppWithEvent.event_selector/1 do
      prototype_task("event 1 prototype task 1")
      prototype_task("event 1 prototype task 2")
  end
  ```

## Task Exit Event Example


In your MyBpmApplication module, enter the following code:

```elixir
defmodule MyBpmApplication do
  use Mozart.BpmProcess

  ## Previous Content Here

  ## Task Exit Event Example

  def exit_subprocess_task_event_selector(message) do
    case message do
      :exit_subprocess_task -> true
      _ -> nil
    end
  end

  defprocess "exit a subprocess task" do
    subprocess_task("subprocess task", model: "subprocess process")
  end

  defprocess "subprocess process" do
    user_task("user task", group: "admin")
  end

  defevent "exit subprocess task",
    process: "exit a subprocess task",
    exit_task: "subprocess task",
    selector: &ME.exit_subprocess_task_event_selector/1 do
      prototype_task("prototype task 1")
      prototype_task("prototype task 2")
  end

end

```

Now start an iex session on your project and paste in the following:

```elixir
alias Mozart.ProcessEngine, as: PE
alias Mozart.ProcessService, as: PS
alias Phoenix.PubSub
MyBpmApplication.load()
{:ok, ppid, uid, business_key} = PE.start_process("exit a subprocess task", %{})
PE.execute(ppid)

```

And you should see the following:

```elixir
iex [10:21 :: 1] > alias Mozart.ProcessEngine, as: PE
Mozart.ProcessEngine
iex [10:21 :: 2] > alias Mozart.ProcessService, as: PS
Mozart.ProcessService
iex [10:21 :: 3] > MyBpmApplication.load()
{:ok, <content deleted for clarity>}
iex [10:21 :: 4] > {:ok, ppid, uid, business_key} = PE.start_process("exit a subprocess task", %{})
10:21:26.446 [info] Start process instance [exit a subprocess task][847016f9-4818-4a30-9f65-3c9a5dcc1db5]
{:ok, #PID<0.296.0>, "847016f9-4818-4a30-9f65-3c9a5dcc1db5",
 "b085931c-89e5-48ca-ae81-e62ea486aef6"}
iex [10:21 :: 5] > PE.execute(ppid)
:ok
10:21:26.450 [info] New subprocess task instance [subprocess task][01dd052c-6cf2-4b95-b2b8-69418f3aa332]
10:21:26.450 [info] Start process instance [subprocess process][df6eca80-8c08-48ff-86cc-d825e8d7375f]
10:21:26.450 [info] New user task instance [user task][827cb198-b40b-4e78-8c80-39a5cbe56a6e]
```

From the logs, we see that the subprocess started and a user task was opened.

Now we will send an event that will cause the subprocess to exit. Additionally, the top level subprocess task will be completed and the tasks on the event will be executed:

```elixir
PubSub.broadcast(:pubsub, "pe_topic", {:event, :exit_subprocess_task})
    
```

You should see:

```elixir
iex [10:21 :: 7] > PubSub.broadcast(:pubsub, "pe_topic", {:event, :exit_subprocess_task})
:ok
10:28:18.310 [info] New prototype task instance [prototype task 1][985d41a3-3e5c-469a-847b-7295a6d405c0]
10:28:18.310 [info] Complete prototype task [prototype task 1]
10:28:18.310 [info] New prototype task instance [prototype task 2][a6394485-3a7f-464f-9a47-3463b6bf87be]
10:28:18.310 [info] Complete prototype task [prototype task 2]
10:28:18.310 [info] Process complete [exit a subprocess task][847016f9-4818-4a30-9f65-3c9a5dcc1db5]
```

Which indicates the expected behavior.