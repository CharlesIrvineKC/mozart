defmodule Mozart.Data.ProcessState do
@moduledoc """

Defines a struct with fields specifying the state of a BPM process execution. The fields
provide the following information:

* **uid**: A unique identifier of a single process model execution.
* **business_key**: A unique identifier for a hierarchy of process model executions
corresponding to a hierarchial process model.
* **parent_uid**: If the process is a child process, this is the pid of the parent process
execution.
* **model_name**: The name of the process model being executed.
* **start_time**: The time when the process started executing.
* **end_time**: The time when the process finished executing.
* **execution_duration**: The duration of time over which the process executed.
* **open_tasks**: a map of open tasks. The key is a process name. The value is the
internal structure of the task.
* **completed_tasks**: A list of completed tasks. List items are task internal
structures.
* **data**: A map of all accumulated process data. Keys are the property names. Values
are the property values.
* **complete**: Indicates whether the process has completed.

```
defstruct [
    :uid,
    :business_key,
    :parent_uid,
    :model_name,
    :start_time,
    :end_time,
    :execute_duration,
    open_tasks: %{},
    completed_tasks: [],
    data: %{},
    complete: false
  ]
end
```

"""
  defstruct [
    :uid,
    :business_key,
    :parent_uid,
    :model_name,
    :start_time,
    :end_time,
    :execute_duration,
    open_tasks: %{},
    completed_tasks: [],
    data: %{},
    complete: false
  ]
end
