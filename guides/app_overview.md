# Introduction to Mozart

## Process Models

The primary concept of *Mozart* is the **Process Model**. A *process model* is an *executable* representation of a business process. *Process models* are implemented using a collection of functions that together comprise a **Domain Specific Language (DSL)** used for the purpose of creating BPM Applications.

If you are a developer working for a bank, you might be asked to develop a process model for handling a customer loan application. A grossly simplified process model for this might look like:

```elixir
  defprocess "process loan application" do
    user_task("record and check loan application",  group: "customer service")
    user_task("determine loan acceptance",          group: "underwriting")
    user_task("inform customer of result",          group: "customer service")
  end
```

## Process Model Tasks

As indicated in the example above, a *process model* is composed of a collection of **tasks**. Each task represents some work that needs to be completed. To **complete** a task means to perform the work required of the task.

Mozart provides around a dozen different types of *tasks*. Tasks are defined using functions in the Mozart DSL.

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
| prototype_task          | Has no behavior. Used for prototyping and subbing. |
| repeat_task             | Repeats a set of tasks while condition is true. |
| reroute_task            | Reroutes a process off the typical (happy) execution path |
| conditional_task        | Implements a conditional task along the typical execution path |

## BPM Process Module

A **BPM Process Module** is an Elixir module containing a set of related **process models, BPM applications, BPM related type definitions** as well as any other normal function definitions. There is an [example process application](https://github.com/CharlesIrvineKC/mozart/blob/main/test/support/home_loan_app.ex) in the Mozart GitHub repository.

*Process applications* must **use Mozart.BpmProcess** to gain access to the Mozart DSL:

```elixir
defmodule MyProcessApplication do
  use Mozart.BpmProcess

  defun send_loan_response(data) do
    # Code to send customer and email loan resonse
  end

  defprocess "process loan application" do
    user_task("record and check loan application", group: "customer service")
    user_task("determine loan acceptance", group: "underwriting")
    service_task("inform customer of result", function: &MyProcessApplication.send_loan_response/1)
  end

  # multiple process model and function definitions

end
```

Declaring **use Mozart.BpmProcess** injects the **MyBpmApplication.load/0** function into your application. Calling this function will load all of your process models into the `Mozart.ProcessService` model repository. Use it now to load your process models:

```elixir
MyProcessApplication.load()
```

## BPM Applications

Each Elixir BPM module can define zero or more **BPM Applications**. Here is an example

```elixir
def_bpm_application("Home Loan", data: "Customer Name,Income,Debt")
```
Each application specifies a user level name, the name of the top level process definition and a set of required 
input parameters.

The purpose of a BPM application is to aid in intergration with external applications, e.g. GUI applications.

## Parameter type specifications

Each Elixir BPM process module can define any number of parameter type definitions. Here are examples
of the currently supported types:

```elixir
def_number_type("number param", min: 0, max: 5)
def_choice_type("choice param", choices: "foo, bar")
def_multi_choice_type("multi choice param", choices: "foo,bar,foobar")
def_confirm_type("confirm param")
```

Type definitions aid in integration with external applications, e.g. GUIs.

## Process Engine

We have said that a Mozart process model is **executable**. What does that mean? After loading the process model as shown above, commands are invoked to start and begin executing the process model. Here is a corresponding code snippet:

```elixir
data = %{loan_amount_requested: 300_000}

{:ok, ppid, uid, _business_key} = ProcessEngine.start_process("process loan application", data)

ProcessEngine.execute(ppid)
```

First, we define some data that the process model will use. Then a *process engine* is spawned by calling **ProcessEngine.start_process/2**. The first parameter specifies the top level *process model* to be executed. As you will see later on, a hierarchy of process instances can be spawned to complete the top level process model. The second argument is data used to initiate process execution. 

The first argument returned is the Elixir *process identifier* of the Elixir GenServer. The secord value returned is a unique identifier of the process execution. This will be useful beyond the lifetime of the Elixir process. Finally, the third value returned is another unique identifier corresponding to the hierarchy of processes spawned to complete the top level process model.

After, the process engine has been spawned, process execution begins by calling **ProcessEngine.execute/1** function, passing it the Elixir PID contained in the return value bound to the variable **ppid**.

## Process Service

We have already seen that the GenServer `Mozart.ProcessService` provides a repository for process models. It provides numerous additional functions [documented in hexdocs](https://hexdocs.pm/mozart/Mozart.ProcessService.html#summary).

## Processes Model Execution

Earlier we said that the job of the process engine is to drive a process model execution to completion. Let's discuss what that means.

### Completing Tasks

When process execution is triggered by calling **ProcessEngine.execute/1**, the first task specified in the process model will be opened for completion.

```elixir
 defprocess "process loan application" do
    user_task("record and check loan application", group: "customer service")
    user_task("determine loan acceptance", group: "underwriting")
    service_task("inform customer of result", function: &MyProcessApplication.send_loan_response/1)
  end
```

Hence, in the process model above, the user task named **record and check loan application** will be opened for completion upon the initiation of process execution.

Completion of this initial task will typically trigger the opening of additional tasks. Every task that completes will potentially trigger the opening of additional tasks. Eventually, a process model will have no open tasks. This signals that execution of the process model is complete and the corresponding process engine will exit.

So, completing the execution of a process model equates to repeatedly opening and completing tasks until the process as a whole is complete.

## Accumulating Data

Almost every task that is opened will need some data to complete. Further, when a task completes, it will introduce some new data for downstream tasks to use. Thus, to a great extent, completing a processes equates to generating a store of accumulated information.

All of the data generated by task completion is stored in the **data** property of `Mozart.ProcessEngine`.

## Producing Side Effects

To be useful, almost all process model executions will produce some side effects. Take the process of processing a bank loan application for example. What are the possible side effects?

* Sending a notice that the loan is approved or declined.
* Depositing money in the customers account.
* Setting up the loan in the banks backend system.

## Conclusion

Hopefully, the mechanics of Business Process Managment is now much clearer. In the newxt section, we will use Mozart to execute business processes.



