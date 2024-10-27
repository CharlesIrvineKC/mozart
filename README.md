# Mozart - An Elixir BPM Platform

Mozart is an open source BPM platform written using Elixir. Instead of using a visual modelling tool to construct BPMN2 models, process models are defined using a BPM Domain Specific Language (DSL). 

## What is a Business Process Management

Business Process Management (BPM) is the organized and directed activity of a company to control, monitor, speed-up and, in general, improve the quality of their business processes. They do this with the aid of a BPM platform such as Mozart.

See [Introduction to BPM](https://hexdocs.pm/mozart/intro_bpm.html) in hexdocs for more information.

## Documentation

View documentation for Mozart in hexdocs at [https://hexdocs.pm/mozart/api-reference.html](https://hexdocs.pm/mozart/api-reference.html)

Another source of learning material is found in Mozart's companion project, **Opera**. See below.

## Two Features Made Possible by Elixir

### A Domain Specific Language (DSL) for BPM Applications

Elixir provides programmers with the ability to seemingly extend Elixir itself by creating domain specific programming idioms. 

In the case of Mozart, this means that programmers can create BPM applications by using BPM specific programming constructs mixed with otherwise everyday Elixir code. Here a very simple but complete example:

```elixir
defmodule MyBpmApplication do
  use Mozart.BpmProcess

  def sum(data) do
    %{"sum" => data["x"] + data["y"]}
  end

  defprocess "add x and y process" do
    service_task("add x and y task", function: :sum, inputs: "x,y")
  end

end
```

This module can be used as-is to start and execute a BPM process engine as shown below. (A small quanity of system output was removed to improve clarity.)

```elixir
iex > MyBpmApplication.load()
iex > {:ok, ppid, uid, _key} = ProcessEntine.start_process("add x and y process", %{"x" => 1, "y" => 2})
[info] Start process instance [add x and y process][b82f5da1-6e5d-44df-b4ed-9064b877e484]

iex > ProcessEngine.execute(ppid)
[info] New service task instance [add x and y task][f396a252-fba4-4804-9fdd-360a6c24ed54]
[info] Complete service task [add x and y task[f396a252-fba4-4804-9fdd-360a6c24ed54]
[info] Process complete [add x and y process][b82f5da1-6e5d-44df-b4ed-9064b877e484]

iex > ProcessService.get_completed_process_data(uid)
%{"sum" => 3, "x" => 1, "y" => 2}
```

With Mozart, process models are not graphically constructed using a visual programming environment typical of most of current BPM development. Mozart's target user community is software development organizations who prefer something that fits seamlessly into their existing development process.

However, visual BPM modelling tools are highly regarded by business process analysts and the resulting graphical process depictions are highly readable by developers and process analysts alike. So, it was essential that the DSL developed produce process models that are as readily understood by process analysts as are BPMN2 process models. We hope you will think we have been reasonably successful achieving this goal.

We anticipate that BPMN2 tools will still be used by Mozart development teams, but only for analysis and documentation. Actual BPM process models will be created with the Mozart BPM DSL.

### A Process for Each Business Process

Another distinguishing feature is that each business top-level process model is executed in a separate Elixir process (GenServer) instance. This is possible due to Elixir's (and Erlang's) unique capacity for highly performant, fault tolerant and massively concurrent multi-processing. Subprocess models do not execute in their own Elixir processes. 

The goal is extremely fast and relable business process model execution. We will be publishing performance metics in the near future to gage Mozart's performance charateristics. Initial results look very promising.

## Opera - A Proof of Concept Mozart GUI

Opera is a POC GUI for Mozart implemented using LiveView. It provides the ability to:

* Load BPM process Elixir modules.
* Start business process instances.
* Filter and complete user tasks.
* Examine the state of active and completed process instances.
* Assign users to work groups.

The application is available in GitHub at https://github.com/CharlesIrvineKC/opera.

It's also deployed to Fly.io at https://opera-holy-bush-2296.fly.dev/. Feel free to experiment with it, and don't worry. It's just a playground of sorts for experimenting and learning.

## Installation

The package can be installed
by adding `mozart` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mozart, "~> 1.0.0"}
  ]
end
```

## Providing Feedback

If you have questions, comments, suggestions, etc. feel free to open issues in GitHub.

## Consulting

Consulting services are avaiable for organizations and businesses which would like assistance using Mozart for business process automation and digitization. If interested, open a GitHub issue in the Mozart project with your contact information.


