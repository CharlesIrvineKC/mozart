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

## What is a Business Process Management

See [Introduction to BPM](https://hexdocs.pm/mozart/intro_bpm.html) in hexdocs 

## Documentation

View documentation in hexdocs at [https://hexdocs.pm/mozart/api-reference.html](https://hexdocs.pm/mozart/api-reference.html)

## Installation

The package can be installed
by adding `mozart` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mozart, "~> 0.1"}
  ]
end
```

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

## Collaboration

Yes, it would be great having other developers join the effort (and discussion).


