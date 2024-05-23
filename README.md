# What is a Business Process?

Companies large and small have business processes that they regularly execute. Let's just call them "processes" for brevity's sake. Insurance companies have processes to process a claim. Banks have processes to approve loans. The government have processes to award contracts. 

Business processes have the following charateristics:

* A business process is comprised of some number of individual tasks. 
* Tasks are performed in a prescribed order. 
* Processes can branch to differing sets of tasks depending on that state of the process.
* Processes can branch to multiple parallel paths as well.
* There are multiple kinds of tasks. Some tasks are performed by users. Some tasks are performed by calling services. There are many other kinds of tasks as well.
* Processes store data to be used by tasks to perform their functions.
* Processes allow tasks to add data for use by downstream tasks.

# What is Business Process Management (BPM)?

The goals of Business Process Management are:

* Better Process Reliablibility
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

Mozart is an open source BPM platform. It is written in Elixir and is in the early stages of development. Currently, process models are defined using a set of Elixir structs providing a modelling language which is somewhat inspired by AWS Step Functions. See [AWS Step Functions](https://docs.aws.amazon.com/step-functions/?icmpid=docs_homepage_appintegration). 

In the future, the intent is to provide a text-based BPM modelling language that is highly readable by process experts with no programming experience. 

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

## Installation

The package can be installed
by adding `mozart` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mozart, "~> 0.1.1"}
  ]
end
```

## Documentation

For a while, documentation is going to be limited....

The basic idea is that first process models are defined and loaded into the system. After that, 
process models are started and executed by providing a model name and some initial data.

If you look in the [demo file](https://github.com/CharlesIrvineKC/mozart/blob/main/lib/mozart/demo.ex) in the Mozart GitHub repository, you will see a set of "def run*" functions. Each one of the loads some process model definitions and then executes them by calling two functions: ProcessEngin.start_process/2 and ProcessEngine.execute/1. Until some actual documentation is available, the best way to figure out what's going on is to examine this file. 

After, that you might take a look at the unit tests, especially those in [https://github.com/CharlesIrvineKC/mozart/blob/main/test/mozart/process_engine_test.exs](https://github.com/CharlesIrvineKC/mozart/blob/main/test/mozart/process_engine_test.exs).

## Major Todo Items

* Code clean up.
* Performance testing (probaly compared with [Camunda](https://camunda.com/) since I am familiar with it.)
* Develop a textual business processs modeling language with will be translated at runtime into native Elixir data structures. The language will be highly readable to process modelers with no programming experience.
* Develop GUIs for:
  * Runtime trouble shooting and monitoring.
  * User and group administration.
  * User task assignment and execution.

## Providing Feedback

If you have questions, comments, suggestions, etc. feel free to open issues in GitHub.


