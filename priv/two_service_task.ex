%ProcessModel{
  name: :two_service_tasks,
  tasks: [
    %Task{
      name: :add_one,
      function: fn data -> Map.put(data, :value, data.value + 1) end,
      next: :add_two
    },
    %Task{
      name: :add_two,
      function: fn data -> Map.put(data, :value, data.value + 2) end,
      next: nil
    },
  ]
}
