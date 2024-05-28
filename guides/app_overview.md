# Introduction to Mozart

## Process Models & Engines

One of the primary concepts of *Mozart* is the **Process Model** implemented by `Mozart.Data.ProcessModel`. A *process model* is an executable representation of a business process. 

If you are a developer working for a bank, you might be asked to develop a process model for handling a customer loan application.

But what does it mean for a process model to be executable? That's where another major concept comes in - the **Process Engine** implemented by `Mozart.ProcessEngine`. A process model and some initial data are loaded into a process engine, after which process execution initiated.

## Process Model Tasks

What happens when a process engine executes a process model? That brings us to the notion of **Tasks**. Tasks are defined in the process model. Each task represents some work that needs to be completed. The job of the process engine is to drive completion of all of the tasks specified in the process model.

Mozart provides arounds a dozen different type of *tasks*. The two most ofen used are the `Mozart.Task.User` task and the `Mozart.Task.Service` task. 

## Process Model Service
 
When a process model has been developed, it is stored in a process model repository for later use. The repository is implemented by `Mozart.ProcessModelService`. When system users are ready to execute a process model, they retrieve it from the repository and use it to start a process engine execution.

## Processes Model Execution

Earlier we said that the job of the process engine is to drive a process model execution to completion. Let's discuss what that means.

### Completing Tasks

Every process model must specify an **initial task**. This will be the first task opened for completion. Completion of the initial task will often, though not always, trigger the opening of addition tasks. Every task that completes will potentially trigger the opening of additional tasks. At least one task in a process model will not trigger any downstream tasks. Eventually, a process model will stop generating new open tasks and it's process engine will terminate.

So, completing the execution of a process model equates to repeatedly opening and completing tasks until the process as a whole is complete.

## Accumulating Data

Amost every task that is opened will need some data to complete. Further, when a task completes, it will introduce some new data for downstream tasks to use. Thus, completing a processes equates to generating a store of information.

## Producing Side Effects

To be useful, almost all process model executions will produce some side effects. Take the process of processing a bank loan application for example. What are the possible side effects?

* Sending a notice that the loan is approved or declined.
* Depositing money in the customers account.
* Setting up the loan in the banks backend system.

## Conclusion

Hopefully, the mechanics of Business Process Managment is now much clearer. In the newxt section, we will use Mozart to execute business processes.


