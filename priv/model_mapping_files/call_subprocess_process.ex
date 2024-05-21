%ProcessModel{
  name: :call_process_model,
  tasks: [
    %Task{
      name: :call_process_task,
      type: :sub_process,
      sub_process: :subprocess_model,
      next: :service_task1
    },
    %Service{
      name: :service_task,
      type: :service,
      function: fn data -> Map.put(data, :value, data.value + 1) end,
      next: nil
    }
  ],
  initial_task: :call_process_task
}


%ProcessModel{
  name: :subprocess_model,
  tasks: [
    %Service{
      name: :service_task1,
      type: :service,
      function: fn data -> Map.put(data, :value, data.value + 1) end,
      next: nil
    }
  ],
  initial_task: :service_task1
}
