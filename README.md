# Mozart - An Elixir BPM Platform

## What is a Business Process Management

See [Introduction to BPM](https://hexdocs.pm/mozart/intro_bpm.html) in hexdocs to get a basic understanding of **Business Process Management (BPM)**.

## Documentation

View documentation for Mozart in hexdocs at [https://hexdocs.pm/mozart/api-reference.html](https://hexdocs.pm/mozart/api-reference.html)

## Introduction

Mozart is an open source BPM platform written using Elixir. Process models are defined using a set of Elixir structs providing a modelling language which is somewhat inspired by AWS Step Functions. See [AWS Step Functions](https://docs.aws.amazon.com/step-functions/?icmpid=docs_homepage_appintegration).  

The most distinguishing feature of Mozart is that each business process model is executed in a GenServer instance, made possible by the well known character of Elixir (and Erlang) multi-processing.

Another important feature is that process models are not graphically constructed using BPMN2. Instead, they are textually represented by struct based Elxir data structures. This makes BPM, hopefully, just another tool in the software developers toolkit.

## Current Use Cases (and Non Use Cases)

* Elixir development teams wanting to explore and potentially implement exploratory BPM applications.
* Non Elixir development teams having the goal of exploring and experimenting with Elixir.
* Mozart is not ready for major enterprise BPM projects. 
* Mozart is not a **low code** or **no code** platform suitable for non developers.

## Installation

The package can be installed
by adding `mozart` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mozart, "~> 0.2"}
  ]
end
```

## Major Todo Items

* Some preliminary performance testing has been done and the results look very promising. More needs to be done and actual metics reported.
* Develop a textual business processs modeling language with will be translated at runtime into native Elixir data structures. The language will be highly readable to process modelers with no programming experience.
* Develop rudimentary GUIs for:
  * Runtime trouble shooting and monitoring.
  * User and group administration.
  * User task assignment and execution.

## Providing Feedback

If you have questions, comments, suggestions, etc. feel free to open issues in GitHub.

## Collaboration

Yes, it would be great having other developers join the effort (and discussion).


