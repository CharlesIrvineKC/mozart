# Mozart - An Elixir BPM Platform

## What is a Business Process Management

See [Introduction to BPM](https://hexdocs.pm/mozart/intro_bpm.html) in hexdocs to get a basic understanding of **Business Process Management (BPM)**.

## Documentation

View documentation for Mozart in hexdocs at [https://hexdocs.pm/mozart/api-reference.html](https://hexdocs.pm/mozart/api-reference.html)

## Introduction

Mozart is an open source BPM platform written using Elixir. A distinguishing feature is that each business process model is executed in a separate Elixir process (GenServer) instance. This is possible due to Elixir's (and Erlang's) unique capacity for highly performant, fault tolerant and massively concurrent multi-processing. 

For now, process models are defined using a set of Elixir structs providing a modelling language which is somewhat inspired by [AWS Step Functions](https://docs.aws.amazon.com/step-functions/?icmpid=docs_homepage_appintegration). However, a user-friendly, BPM specific DSL is currently under development. The goal is to create a developer-targeted DSL which can be incorporated into modern CI/CD devops infrastructures.

Conversely, process models will not be graphically constructed using a visual programming environment typical of BPMN2. We believe that this kind of development is avoided by a substantial segment of the software development community and in some instances is not condusive to CI/CD developmemnt processes.

However, visual modelling tools are highly regarded by business process analysts and the resulting graphical process depictions are highly readable by developers and process analysts alike. So, it is essential that the DSL currently under development produce process models that are are as readily understood by process analysts as are BPMN2 process models.

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

* Develop a DSL which will be translated at runtime into native Elixir data structures. The language will be highly readable to process modelers with no programming experience. **Currently in active development.** See [unit tests](https://github.com/CharlesIrvineKC/mozart/blob/main/test/mozart/dsl_process_engine_test.exs) to view progress and sample business process definitions.
* Develop rudimentary GUIs for:
  * Runtime trouble shooting and monitoring.
  * User and group administration.
  * User task assignment and execution.

## Providing Feedback

If you have questions, comments, suggestions, etc. feel free to open issues in GitHub.

## Collaboration

Yes, it would be great having other developers join the effort (and discussion).


