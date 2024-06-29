# Introduction to Mozart

## Process Models

The primary concept of *Mozart* is the **Process Model**. A *process model* is an executable representation of a business process. *Process models* are implemented using a collection of macros that together comprise a **Domain Specific Language (DSL)** used for the purpose of creating BPM Applications.

If you are a developer working for a bank, you might be asked to develop a process model for handling a customer loan application, which might look like this:

```elixir
  defprocess "process loan application" do
    user_task("record and check loan application",  groups: "customer service")
    user_task("determine loan acceptance",          groups: "underwriting")
    user_task("inform customer of result",          groups: "customer service")
  end
```

## Process Model Tasks

As indicated in the example above, a *process model* is composed of a collection of **tasks**. Each task represents some work that needs to be completed. To **complete** a task means to perform the work required of the task.

Mozart provides arounds a dozen different types of *tasks*. Tasks are defined using macros in the Mozart DSL.

The task types currently supported are:

| Task Type               |  Description |
|-----|-----|
| user_task               | Performed by a user |
| service_task            | Performed by calling a service. |
| subprocess_task         | Performed by calling a subprocess. |
| timer_task              | Waits for expiration of a timer. |
| receive_task            | Waits for a subscribed PubSub event. |
| send_task               | Sends a PubSub event. |
| rule_task               | Performed by evaluating a set of rules represented in a table. |
| case_task               | Selects one of many process paths. |
| parallel_task           | Initiates two or more parallel process paths. |

## Process Application

A **process application** is simply a set of related **process models** grouped together in an Elixir module. There is an [example process application](https://github.com/CharlesIrvineKC/mozart/blob/main/test/support/home_loan_app.ex) in the Mozart GitHub repository.

*Process applications* must **use Mozart.BpmProcess** to gain access to the Mozart DSL:

```elixir
defmodule MyProcessApplication do
  use Mozart.BpmProcess
  .... multiple process model definitions
end
```

## Process Engine

We have said that a Mozart process model is **executable**. What does that mean? Each process model is loaded into an instance of a Mozart process engine, implemented by the GenServer `Mozart.ProcessEngine`. After loading the process model, a command is invoked to to begin executing the process model. Here is a corresponding code snippet:

```elixir
{:ok, ppid, uid, _process_key} = ProcessEngine.start_process("one service task process", %{x: 3})
ProcessEngine.execute(ppid)
```

First, a *process engine* is spawned by calling **ProcessEngine.start_process/2**. The first parameter specifies the top level *process model* to be executed. As you will see later on, a hierarchy of process instances can be spawned to complete the top level process model. The second argument is data used to initiate process execution. 

The first argument returned is the Elixir *process identifier* of the Elixir GenServer. The secord value returned is a unique identifier of the process execution. This will be useful beyond the lifetime of the Elixir process. Finally, the third value returned is another unique identifier corresponding to the hierarchy of processes spawned to complete the top level process model.

## Process Service
 
(Needs an update for more process services functions) When a process model has been developed, it is stored in a process model repository for later use. The repository is implemented by `Mozart.ProcessService`. When system users are ready to execute a process model, they retrieve it from the repository and use it to start a process engine execution.

## Processes Model Execution

Earlier we said that the job of the process engine is to drive a process model execution to completion. Let's discuss what that means.

### Completing Tasks

Every process model must specify an **initial task**. This will be the first task opened for completion. Completion of the initial task will often, though not always, trigger the opening of additional tasks. Every task that completes will potentially trigger the opening of additional tasks. At least one task in a process model will not trigger any downstream tasks. Eventually, a process model will stop generating new open tasks and it's process engine will terminate.

So, completing the execution of a process model equates to repeatedly opening and completing tasks until the process as a whole is complete.

## Accumulating Data

Almost every task that is opened will need some data to complete. Further, when a task completes, it will introduce some new data for downstream tasks to use. Thus, to a great extent, completing a processes equates to generating a store of information.

All of the data generated by task completion is stored in the **data** property of `Mozart.ProcessEngine`.

## Producing Side Effects

To be useful, almost all process model executions will produce some side effects. Take the process of processing a bank loan application for example. What are the possible side effects?

* Sending a notice that the loan is approved or declined.
* Depositing money in the customers account.
* Setting up the loan in the banks backend system.

## Conclusion

Hopefully, the mechanics of Business Process Managment is now much clearer. In the newxt section, we will use Mozart to execute business processes.



