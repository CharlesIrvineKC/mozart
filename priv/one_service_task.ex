alias Mozart.Data.ProcessModel
alias Mozart.Data.Task

%ProcessModel{
  name: :one_service_task,
  tasks: [
    %Task{
      name: :add_one,
      function: fn data -> Map.put(data, :value, data.value + 1) end,
      next: nil
    }

  ]
}
