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

Later we'll discuss tasks in great detail, but there are a couple of things you need to know now. A process model specifies all the tasks that might get completed. We say "might" since 



