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

This is difficult to answer exactly, but BPM may be applicable when:

* Processes are performed on a regular basis.
* Process are well defined.
* Multiple business groups and people participate in process execution.

# Mozart

Mozart will be a open source BPM platform. It is written in Elixir and is in the early stages of development. A distinguishing characteristic is that, instead of using BPNM2, it will provide a text-based BPM modelling language that is highly readable by process experts with no programming experience. The modelling language is inspired by AWS Step Functions. See [AWS Step Functions](https://docs.aws.amazon.com/step-functions/?icmpid=docs_homepage_appintegration).

The modeling elements currently supported are:

* User Task
* Service Task
* Subprocess Task
* Timer Task
* Receive Event Task
* Decision Task
* Exclusive Gate
* Parallel Gate
* Parallel Join

## Current Development Status

* There is a working process execution engine.
* Each business process, including each subprocess, runs in it's own GenServer process.
* Example business process definitions are in test_models.ex_doc
* Business process models are, for now, written using Elxir data structues. (See Todo Section)
* The examples can be run with "mix test".


## Todo

* Implement send event task.
* Implement decision task.
* Publish 0.1 release to hex.
* Develop a textual business processs modeling language with will be translated at runtime into native Elixir data structures. The language will be highly readable to process modeler with no programming experience.
* Develop GUIs for:
  * Runtime trouble shooting and monitoring.
  * User and group administration.
  * User task assignment and execution.

## Providing Feedback

If you have questions, comments, suggestions, etc. feel free to open issues in GitHub.


