defmodule Mozart.Data.ProcessState do
@moduledoc """

```
defstruct [
    :uid,
    :process_key,
    :parent_pid,
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

This struct is used to represent the state of a `Mozart.ProcessEngine` execution.

Example: (incrementally populated throughout process execution.)

```
%Mozart.Data.ProcessState{
  uid: "74146e68-088e-42b6-965e-20f4d7dbae16",
  process_key: "74146e68-088e-42b6-965e-20f4d7123456"
  parent_pid: nil,
  model_name: :call_external_service,
  start_time: ~U[2024-05-27 15:22:01.847683Z],
  end_time: ~U[2024-05-27 15:22:02.277273Z],
  execute_duration: 429590,
  open_tasks: %{},
  completed_tasks: [
    %{
      data: %{},
      function: #Function<0.23164178/1 in Mozart.ProcessModels.TestModels.call_exteral_services/0>,
      name: :get_api_data,
      type: :service,
      next: nil,
      __struct__: Mozart.Task.Script,
      uid: "e3326041-d203-46b2-8141-907f71421398",
      process_uid: "74146e68-088e-42b6-965e-20f4d7dbae16"
    }
  ],
  data: %{
    todo_data: %{
      "completed" => false,
      "id" => 1,
      "title" => "delectus aut autem",
      "userId" => 1
    }
  },
  complete: true
}
```

"""
  defstruct [
    :uid,
    :process_key,
    :parent_pid,
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
