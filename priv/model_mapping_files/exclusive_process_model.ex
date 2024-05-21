%ProcessModel{
  name: :choice_process_model,
  tasks: [
    %Choice{
      name: :choice_task,
      choices: [
        %{
          expression: fn data -> data.value < 1000000 end,
          next: :is_low
        },
        %{
          expression: fn data -> data.value >= 1000000 end,
          next: :is_high
        }
      ]
    },
    %Service{
      name: :is_high,
      function: fn data -> Map.merge(data, %{is_high: true}) end
    },
    %Service{
      name: :is_low,
      function: fn data -> Map.merge(data, %{bar: :bar}) end
    }
  ],
  initial_task: :choice_task
},
