defmodule Mozart.Util do

  alias Mozart.Data.Task
  alias Mozart.Data.ProcessModel

  def get_simple_model() do
    %ProcessModel{
        name: :foo,
        tasks: [
          %Task{
            name: :foo,
            type: :service,
            function: fn data -> Map.merge(data, %{bar: :bar}) end,
            next: nil
          }
        ],
        initial_task: :foo
      }
  end

  def get_simple_user_task_model() do
    %ProcessModel{
        name: :foo,
        tasks: [
          %Task{
            name: :foo,
            type: :user,
            assigned_groups: ["admin"],
            next: nil
          }
        ],
        initial_task: :foo
      }
  end

  def get_simple_user_task_then_service_task_model() do
    %ProcessModel{
        name: :user_task_then_service,
        tasks: [
          %Task{
            name: :user_task_1,
            type: :user,
            assigned_groups: ["admin"],
           next: :increment_by_one_task
          },
          %Task{
            name: :increment_by_one_task,
            type: :service,
            function: fn map -> Map.put(map, :value, map.value + 1) end,
            next: nil
          }
        ],
        initial_task: :user_task_1
      }
  end

  def get_service_task_then_simple_user_task_model() do
    %ProcessModel{
        name: :user_task_then_service,
        tasks: [
          %Task{
            name: :increment_by_one_task,
            type: :service,
            function: fn map -> Map.put(map, :value, map.value + 1) end,
            next: :user_task_1
          },
          %Task{
            name: :user_task_1,
            type: :user,
            assigned_groups: ["admin"],
            next: nil
          },
        ],
        initial_task: :increment_by_one_task
      }
  end

  def get_increment_by_one_model() do
    %ProcessModel{
        name: :increment_by_one_process,
        tasks: [
          %Task{
            name: :increment_by_one_task,
            type: :service,
            function: fn map -> Map.put(map, :value, map.value + 1) end,
            next: nil
          }
        ],
        initial_task: :increment_by_one_task
      }
  end

  def get_increment_twice_by_one_model() do
    %ProcessModel{
        name: :increment_by_one_process,
        tasks: [
          %Task{
            name: :increment_by_one_task,
            type: :service,
            function: fn map -> Map.put(map, :value, map.value + 1) end,
            next: :increment_by_two_task
          },
          %Task{
            name: :increment_by_two_task,
            type: :service,
            function: fn map -> Map.put(map, :value, map.value + 2) end,
            next: nil
          },
        ],
        initial_task: :increment_by_one_task
      }
  end

  def get_increment_three_times_by_one_model() do
    %ProcessModel{
        name: :increment_by_one_process,
        tasks: [
          %Task{
            name: :increment_by_one_task,
            type: :service,
            function: fn map -> Map.put(map, :value, map.value + 1) end,
            next: :increment_by_two_task
          },
          %Task{
            name: :increment_by_two_task,
            type: :service,
            function: fn map -> Map.put(map, :value, map.value + 2) end,
            next: :increment_by_three_task
          },
          %Task{
            name: :increment_by_three_task,
            type: :service,
            function: fn map -> Map.put(map, :value, map.value + 3) end,
            next: nil
          },
        ],
        initial_task: :increment_by_one_task
      }
  end
end
