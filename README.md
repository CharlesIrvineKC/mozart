# Mozart - An Elixir BPM Platform

Mozart is an open source BPM platform written using Elixir. 

## What is a Business Process Management

Business Process Management (BPM) is the organized and directed activity of a company to control, monitor, speed-up and, in general, improve the quality of their business processes. They do this with the aid of a BPM platform such as Mozart.

See [Introduction to BPM](https://hexdocs.pm/mozart/intro_bpm.html) in hexdocs for more information.

## Documentation

View complete documentation for Mozart in hexdocs at [https://hexdocs.pm/mozart/api-reference.html](https://hexdocs.pm/mozart/api-reference.html)

## Two Features Made Possible by Elixir

### A Domain Specific Language (DSL) for BPM Applications

Elixir provides programmers with the ability to seemingly extend Elixir itself by creating domain specific programming idioms. 

In the case of Mozart, this means that programmers can create BPM applications by using BPM specific programming constructs mixed with otherwise everyday Elixir code. Here a very simple but complete example:

```elixir
defmodule MyBpmApplication do
  use Mozart.BpmProcess

  def sum(data) do
    %{sum: data.x + data.y}
  end

  defprocess "add x and y process" do
    service_task("add x and y task", function: &MyBpmApplication.sum/1, inputs: "x,y")
  end

end
```

This module can be used as-is to start and execute a BPM process engine as shown below. (A small quanity of system output was removed to improve clarity.)

```
iex > MyBpmApplication.load()
iex > {:ok, ppid, uid, _key} = ProcessEntine.start_process("add x and y process", %{x: 1, y: 1})
[info] Start process instance [add x and y process][b82f5da1-6e5d-44df-b4ed-9064b877e484]

iex > ProcessEngine.execute(ppid)
[info] New service task instance [add x and y task][f396a252-fba4-4804-9fdd-360a6c24ed54]
[info] Complete service task [add x and y task[f396a252-fba4-4804-9fdd-360a6c24ed54]
[info] Process complete [add x and y process][b82f5da1-6e5d-44df-b4ed-9064b877e484]

iex > ProcessService.get_completed_process_data(uid)
%{sum: 2, y: 1, x: 1}
```

With Mazart, process models are not graphically constructed using a visual programming environment typical of most of current BPM development. Mozart's target user community is software development organizations who prefer something that fits seamlessly into their existing development process.

However, visual BPM modelling tools are highly regarded by business process analysts and the resulting graphical process depictions are highly readable by developers and process analysts alike. So, it was essential that the DSL developed produce process models that are as readily understood by process analysts as are BPMN2 process models. We hope you will think we have been reasonably successful achieving this goal.

We anticipate that BPMN2 tools will still be used by Mozart development teams, but only for analysis and documentation. Actual BPM process models will be created with the Mozart BPM DSL.

### A Process for Each Business Process

Another distinguishing feature is that each business process model is executed in a separate Elixir process (GenServer) instance. This is possible due to Elixir's (and Erlang's) unique capacity for highly performant, fault tolerant and massively concurrent multi-processing. 

The goal is extremely fast and relable business process model execution. We will be publishing performance metics in the near future to gage Mozart's performance charateristics. Initial results look very promising.

## Project Status

Mozart is ready for serious experimental use. A 1.0.0 release is targeted for late 2024.

It requires Elixir programming, so if you already use Elixir you can be immediately productive. If you aren't using Elixir, hopefully you will have time to take a look at this amazing programming language.

We will be very receptive to quickly resolve any issues you encounter and answer your questions. For either of these, please create an issues in GitHub.

A proof-of-concept GUI is under active developement. It provides the ability to:

* Load BPM process Elixir modules.
* Start business process instances.
* Complete user tasks.
* Examine the state of active and completed process instances.

The application is called **Opera** and is available in GitHub at https://github.com/CharlesIrvineKC/opera.

It's also deployed to Fly.io at https://opera-holy-bush-2296.fly.dev/tasks.

## Installation

The package can be installed
by adding `mozart` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mozart, "~> 0.6.0"}
  ]
end
```

## Providing Feedback

If you have questions, comments, suggestions, etc. feel free to open issues in GitHub.

## Consulting

Consulting services are avaiable for organizations and businesses which would like assistance
using Mozart for business process automation and digitization. If interested, open a GitHub issue in the Mozart project with your contact information.


