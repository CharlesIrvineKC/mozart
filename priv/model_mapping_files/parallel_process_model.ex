alias Mozart.Data.ProcessModel
alias Mozart.Task.Task

%ProcessModel{
  name: :paralled_process_model,
  tasks: [
    %Task{
      name: :two_flows,
      type: parallel,
      multi_next: [:add_one, :add_three]
    },
    %Service{
      name: :add_one,
      type: :service,
      function: fn data -> Map.put(data, :value, data.value + 1) end,
      next: :add_two
    },
    %Service{
      name: :add_two,
      type: :service,
      function: fn data -> Map.put(data, :value, data.value + 2) end,
      next: nil
    },
    %Service{
      name: :add_three,
      type: :service,
      function: fn data -> Map.put(data, :value, data.value + 3) end,
      next: nil
    }
  ]
}
