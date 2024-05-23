# What is a Business Process?

Companies large and small have business processes that they regularly execute. Let's just call them "processes" for brevity's sake. Insurance companies have processes to process a claim. Banks have processes to approve loans. The government have processes to award contracts. 

Business processes have the following charateristics:

* A business process is comprised of some number of individual tasks. 
* Tasks are performed in a prescribed order. 
* Processes can branch to differing sets of tasks depending on that state of the process.
* Processes can branch to multiple parallel paths as well.
* There are multiple kinds of tasks. Some tasks are performed by users. Some tasks are performed by calling services. 
* Store data used by tasks to perform their functions.
* Allow tasks to add data for use by downstream tasks.

# What is Business Process Management (BPM)?

The goals of Business Process Management are:

* More Reliablibility
* Faster Process Execugtion
* Reduced Training Requirements
* Incremental Process Improvement
* Provide Process Metrics
* Cost Savings

Business Process Managemnt is implemented with the aid of a BPM platform of some sort. There are are dozens of commerical BPM platforms and they can be quite expensive, potentially costing millions of dollars a year.

BPM platforms provide the following functions:

* Provide developers with the ability of define and store process models.
* Provide developers with the ability have certain tasks completed by making service calls.
* Provide users and administrators with the ability to start process instances.
* Provide users with the ability to assign user tasks to specified users.
* Prvide users with the ability to assign user tasks to members of a specified user group.

# When is BPM Applicable

This is difficult to answer exactly, but BPM may be applicable when:

* Processes are performed on a regular basis.
* Process are well defined.
* Multiple business groups and people participate in process execution.

# Mozart

Mozart will be a open source BPM platform. It is written in Elixir and is in the early stages of development. A distinguishing characteristic is that, instead of using BPNM2, it will provide a text-based BPM modelling language that is highly readable by process experts with no programming experience. The modelling language is inspired by AWS Step Functions. See [AWS Step Functions](https://docs.aws.amazon.com/step-functions/?icmpid=docs_homepage_appintegration).

The modeling elements currently supported are:

| Element Type               |  Description |
|-----|-----|
| User Task               | Performed by a user |
| Service Task            | Performed by calling a service. |
| Subprocess Task         | Performed by calling a subprocess. |
| Timer Task              | Waits for expiration of a timer. |
| Receive Task            | Waits for a subscribed PubSub event. |
| Send Task               | Sends a PubSub event. |
| Decision Task           | Perform by evaluating a decision block (Tablex) |
| Exclusive Gate          | Selects one of many process paths. |
| Parallel Gate           | Initiates two or more process paths. |
| Parallel Join           | Sychronizes on completion of two or more process paths. |

## Current Development Status

* There is a working process execution engine.
* Each business process, including each subprocess, runs in it's own GenServer process.
* Example business process definitions are in test_models.ex_doc
* Business process models are, for now, written using Elxir data structues. (See Todo Section)
* The examples can be run with "mix test".

## Installation

The package can be installed
by adding `mozart` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mozart, "~> 0.1.0"}
  ]
end
```

## Documentation

For a while, documentation is going to be limited....

The basic idea is that first process models are defined and loaded into the system. After that, 
process models are started and executed by providing a model name and some initial data.

If you look in the [demo file](https://github.com/CharlesIrvineKC/mozart/blob/main/lib/mozart/demo.ex) in the Mozart GitHub repository, you will see a set of "def run*" functions. Each one of the loads some process model definitions and then executes them by calling two functions: ProcessEngin.start_process/2 and ProcessEngine.execute/1.

Until some actual documentation is available, the best way to figure out what's going on is to examine this file.

## Todo

* Publish 0.1 release to hex.
* Develop a textual business processs modeling language with will be translated at runtime into native Elixir data structures. The language will be highly readable to process modelers with no programming experience.
* Develop GUIs for:
  * Runtime trouble shooting and monitoring.
  * User and group administration.
  * User task assignment and execution.

## Providing Feedback

If you have questions, comments, suggestions, etc. feel free to open issues in GitHub.


