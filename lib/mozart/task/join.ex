defmodule Mozart.Task.Join do
  @moduledoc """
  Used to join parallel execution paths.

  Example:

  ```
  %ProcessModel{
        name: :parallel_process_model,
        tasks: [
          %Parallel{
            name: :parallel_task,
            multi_next: [:foo, :bar]
          },
          %Service{
            name: :foo,
            function: fn data -> Map.merge(data, %{foo: :foo}) end,
            next: :join_task
          },
          %Service{
            name: :bar,
            function: fn data -> Map.merge(data, %{bar: :bar}) end,
            next: :foo_bar
          },
          %Service{
            name: :foo_bar,
            function: fn data -> Map.merge(data, %{foo_bar: :foo_bar}) end,
            next: :join_task
          },
          # Here's the Join task. Must receive all inputs before completing.
          %Join{
            name: :join_task,
            inputs: [:foo, :foo_bar],
            next: :final_service
          },
          %Service{
            name: :final_service,
            function: fn data -> Map.merge(data, %{final: :final}) end
          }
        ],
        initial_task: :parallel_task
      }
  ```
  """
  defstruct [
    :name,
    :next,
    :uid,
    :start_time,
    :finish_time,
    :duration,
    inputs: [],
    type: :join
  ]
end
