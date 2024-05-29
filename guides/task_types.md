# Mozart Task Types

This guide will describe and give examples of each of the Mozart task types. We will use an [example file](https://github.com/CharlesIrvineKC/mozart/blob/main/lib/mozart/examples/examples.ex) from the Mozart GitHub repository. Copy it to your repository if you would like to follow along.

## Properties Common to All Task Types

All of the task types have the following properties:
* **name**: an atome specifying the name of the task. Must be unique within the scope of the parent process model.
* **next**: the name of the task that should be opened after completion of the current task. Exception: The task type `Mozart.Task.Paralled` doesn't have a next field. Instead, it has a multi_next field, which specifies next tasks that should be opened in parallel.
* **uid**: When a task is opened (instantiated) it is assigned a unique identifier, i.e. its *uid*.
* **type**: Specifies the type of the task. This value is defaulted automatically for each task type.

## Service Task

A **Service Task** (`Mozart.Task.Service`) performs its work by calling an Elixir function. This function could perform a computation, call an external JSON service, retrieve data from a database, etc.

A service task has two unique fields: **:function**, and **:data**.

## User Task
## Decision Task
## Parallel Task
## Subprocess Task
## Timer Task
## Join Task
## Send Task
## Receive Task

