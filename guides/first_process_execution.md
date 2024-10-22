# First Process Execution

Now we will put together what we've lerned so far to execute a process model. 

## To Follow Along..

To follow along create a new Elxir **mix** project and then add Mozart as a dependency in your **mix.exs** project file.

Create a project:

```
$ mix new mozart_play
```

Open mix.exs and add **mozart** dependency:

```elixir
  defp deps do
    [
      {:mozart, "~> 0.9"}
    ]
  end
```

Get dependencies:

```
$ mix deps.get
```

## Create BPM Application

First you need to create a BPM application module. In it you will specify your process models and any needed supported functions. Add the file lib/my_bpm_application.ex to your project:

```elixir
defmodule MyBpmApplication do
  use Mozart.BpmProcess

  # Your process models and supporting functions will go here.

end
```

## Construct the Process Model

First, let us construct a simple process model that will have a single service task. The service task will simply return the sum of two input properties. Update your BPM application module as follows:

```elixir
defmodule MyBpmApplication do
  use Mozart.BpmProcess

  def sum(data) do
    %{sum: data["x"] + data["y"]}
  end

  defprocess "add x and y process" do
    service_task("add x and y task", function: :sum, inputs: "x,y")
  end

end
```

## Load the Process Model into repository

Now let's load this process model into the process model repository, which is implemented by `Mozart.ProcessService`. First, start an iex session with **iex -S mix** and paste a couple of aliases into your iex session:

```elixir
alias Mozart.ProcessEngine, as: PE
alias Mozart.ProcessService, as: PS

```

Now we are ready to load our process model into the repository. Copy the following into your iex session:

```elixir
MyBpmApplication.load()

```

You should see:

````
iex [15:06 :: 3] > MyBpmApplication.load()
%{
  active_process_groups: %{},
  active_processes: %{},
  restart_state_cache: %{},
  user_task_db: #PID<0.1995.0>,
  completed_process_db: #PID<0.2000.0>,
  process_model_db: #PID<0.2004.0>,
  bpm_application_db: #PID<0.2008.0>,
  process_state_db: #PID<0.2013.0>,
  type_db: #PID<0.2017.0>
}
````

The function **MyBpmApplication.load/0** was created for you automatically when you inserted **use Mozart.BpmProcess** into your module definition. The output shows the internal state of the system. Disregard this for now.

## Start a Process Engine and Execute the Process Model

Now let us start a process engine, initializing it with our process model and some data. Then we call the function that will invoke process execution. Copy the following into your iex session:

```elixir
{:ok, ppid, uid, _key} = PE.start_process("add x and y process",%{"x" => 1, "y" => 2})

```

You should now see something like:

```
10:04:26.242 [info] Start process instance [add x and y process][a57d93d4-fc97-4a3c-89f6-989c088c96a7]
{:ok, #PID<0.457.0>, "a57d93d4-fc97-4a3c-89f6-989c088c96a7", "d41dc645-2417-4778-bb18-fccf2e6e44f6"}
```

We started a process instance using `Mozart.ProcessEngin.start_process/2`. We passed it the name of the process model to be executed and some initial data required for process execution. The function call returned a tuple with three values: 

* The **pid** of the resulting process engine.
* The **uid** of the process instance. Every process execution will be given a unique identifier. You will see how this is used going forward.
* Finally, a **business_key** is returned. Process models are hierarchial, meaning they can be composed of multiple, nested subprocesses. The top level business process and all of its subprocesses will share the same *business_key*. Here, were aren't going to be using the *process key*, but we will in subsequent examples.

After creating the process engine instance, we then call `Mozart.ProcessEngine.execute/1` which causes the process engine to start completing any tasks that are ready to be completed. Let's do that now:

```
PE.execute(ppid)

```

After calling the *ProcessEngine.execute* function, you should see something like:

```elixir
iex [08:50 :: 23] > PE.execute(ppid)
:ok
10:14:43.450 [info] New service task instance [add x and y task][2dd65cc0-ca74-4b4d-9219-db36e486dd68]
10:14:43.454 [info] Complete service task [add x and y task[2dd65cc0-ca74-4b4d-9219-db36e486dd68]
10:14:43.456 [info] Exit process: process complete [add x and y process][3261eb1a-7b2a-438a-aa2a-3c9ec646e8f7]
```

The logs show that:

1. A new service task was opened.
1. The service task completed.
1. And finally the process engine completed executing the process model.

## Verify the Results

Let's verify the results of our process model execution by calling **ProcessService.get_completed_process_data/1**. Copy the following into your iex session:

```elixir
PS.get_completed_process_data(uid)

```

and you should see:

```elixir
iex [08:50 :: 26] > PS.get_completed_process_data(uid)
%{:sum => 3, "x" => 1, "y" => 2}
```

We see that a **sum** property was added to process data whose value is the sume of the properties **x** and **y**..

