# What is a Business Process?

Companies large and small have business processes that they regularly execute. Let's just call them "processes" for brevity's sake. Insurance companies have processes to process a claim. Banks have processes to approve loans. The government have processes to award contracts. 

# What is Business Process Management (BPM)?

The goals of Business Process Management are:

* More Reliablibility
* Faster Process Execugtion
* Reduced Training Requirements
* Incremental Process Improvement
* Provide Process Metrics
* Cost Savings

Business Process Managemnt is implemented with the aid of a BPM platform of some sort. There are are dozens of commerical BPM platforms and they can be quite expensive, potentially costing millions of dollars a year.

# When is BPM Applicable

BPM is applicable when:

* Processes are performed on a regular basis.
* Process are well defined.
* Multiple business groups and people participate in process execution.

# Mozart

Mozart will be a open source BPM platform. It is written in Elixir and is in the early stages of development. It's distinguishing characteristic will be that it is targeted for use by software engineers. It will offer a text-based BPM modelling language that is highly readable by process experts with no programming experience.

## Current Status

* There is a working process execution engine.
* Each business process runs in it's own GenServer process.
* Example business process definitions are in test_models.ex_doc
* Business process models are written using Elxir data structues. (See Todo Section)
* The examples can be run with "mix test".
* The modelling language is inspired by AWS Step Functions
* The modeling elements current supported are:
  * User Tasks
  * Service Tasks
  * Subprocess Tasks
  * Exclusive Gates
  * Parallel Gates
  * Parallel Joins

## Todo

* Develop a textual business processs modeling language with will be translated at runtime into native Elixir data structures. The language will be highly readable to process modeler with no programming experience.
* Develop GUIs for:
  * Runtime trouble shooting and monitoring.
  * User and group administration.
  * User task assignment and execution.

## Other

If you have questions, comments, suggestions, etc. feel free to open issues in GitHub.

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/mozart>.

