defmodule Mozart.Task.Common do
  defmacro __using__(_) do
    quote do
      import Mozart.ProcessEngine
      require Logger
    end
  end
end

defprotocol Mozart.Task do
  def completable(task)
  def complete_task(task, state)
end

defimpl Mozart.Task, for: Mozart.Task.Case do
  use Mozart.Task.Common

  def completable(_case), do: true

  def complete_task(task, state) do
    Logger.info("Complete case task [#{task.name}][#{task.uid}]")

    next_task_name =
      Enum.find_value(task.cases, fn case -> if case.expression.(state.data), do: case.next end)

    state
    |> create_next_tasks(next_task_name)
    |> update_completed_task_state(task, task.next)
    |> execute_process()
  end
end

defimpl Mozart.Task, for: Mozart.Task.Conditional do
  use Mozart.Task.Common

  def completable(conditional), do: conditional.complete
  def complete_task(task, state) do
    Logger.info("Complete conditional task [#{task.name}]")
    update_completed_task_state(state, task, task.next) |> execute_process()
  end
end

defimpl Mozart.Task, for: Mozart.Task.Join do
  use Mozart.Task.Common

  def completable(join), do: join.inputs == []

  def complete_task(task, state) do
    Logger.info("Complete service task [#{task.name}[#{task.uid}]")

    input_data =
      if task.inputs,
        do: Map.filter(state.data, fn {k, _v} -> Enum.member?(task.inputs, k) end),
        else: state.data

    output_data = apply(task.module, task.function, [input_data])

    Map.put(state, :data, Map.merge(state.data, output_data))
    |> update_completed_task_state(task, task.next)
    |> execute_process()
  end
end

defimpl Mozart.Task, for: Mozart.Task.Parallel do
  use Mozart.Task.Common

  def completable(_parallel), do: true

  def complete_task(task, state) do
    Logger.info("Complete parallel task [#{task.name}]")
    next_states = task.multi_next

    update_for_completed_task(state, task)
    |> process_next_task_list(next_states, task.name)
    |> execute_process()
  end
end

defimpl Mozart.Task, for: Mozart.Task.Prototype do
  use Mozart.Task.Common

  def completable(_prototype), do: true

  def complete_task(task, state) do
    Logger.info("Complete prototype task [#{task.name}]")
    state = if task.data, do: Map.put(state, :data, Map.merge(state.data, task.data)), else: state
    update_completed_task_state(state, task, task.next) |> execute_process()
  end
end

defimpl Mozart.Task, for: Mozart.Task.Receive do
  use Mozart.Task.Common

  def completable(receive), do: receive.complete

  def complete_task(task, state) do
    Logger.info("Complete receive event task [#{task.name}]")

    Map.put(state, :data, Map.merge(state.data, task.data))
    |> update_completed_task_state(task, task.next)
    |> execute_process()
  end
end

defimpl Mozart.Task, for: Mozart.Task.Repeat do
  use Mozart.Task.Common

  def completable(repeat), do: repeat.complete

  def complete_task(task, state) do
    Logger.info("Complete repeat task [#{task.name}]")
    update_completed_task_state(state, task, task.next) |> execute_process()
  end
end

defimpl Mozart.Task, for: Mozart.Task.Reroute do
  use Mozart.Task.Common

  def completable(_reroute), do: true

  def complete_task(task, state) do
    Logger.info("Complete reroute task [#{task.name}][#{task.uid}]")

    next_task_name =
      if apply(task.module, task.condition, [state.data]),
        do: task.reroute_first,
        else: task.next

    state
    |> create_next_tasks(next_task_name)
    |> update_completed_task_state(task, nil)
    |> execute_process()
  end
end

defimpl Mozart.Task, for: Mozart.Task.Rule do
  use Mozart.Task.Common

  def completable(_rule), do: true

  def complete_task(task, state) do
    Logger.info("Complete rule task [#{task.name}[#{task.uid}]")

    filtered_data = Map.filter(state.data, fn {k, _v} -> Enum.member?(task.inputs, k) end)

    decide_args =
      Enum.map(filtered_data, fn {key, value} -> {String.to_existing_atom(key), value} end)

    decide_result = Tablex.decide(task.rule_table, decide_args)

    decide_result = Enum.map(decide_result, fn {k, v} -> {Atom.to_string(k), v} end)
    data = Map.new(decide_result)
    data = Map.merge(state.data, data)

    Map.put(state, :data, data)
    |> update_completed_task_state(task, task.next)
    |> execute_process()
  end
end

defimpl Mozart.Task, for: Mozart.Task.Send do
  use Mozart.Task.Common
  def completable(_send), do: true

  def complete_task(task, state) do
    Logger.info("Complete send event task [#{task.name}[#{task.uid}]")
    update_completed_task_state(state, task, task.next) |> execute_process()
  end
end

defimpl Mozart.Task, for: Mozart.Task.Service do
  use Mozart.Task.Common

  def completable(_service), do: true

  def complete_task(task, state) do

    Logger.info("Complete service task [#{task.name}[#{task.uid}]")

    input_data =
      if task.inputs,
        do: Map.filter(state.data, fn {k, _v} -> Enum.member?(task.inputs, k) end),
        else: state.data

    output_data = apply(task.module, task.function, [input_data])

    Map.put(state, :data, Map.merge(state.data, output_data))
    |> update_completed_task_state(task, task.next)
    |> execute_process()
  end
end

defimpl Mozart.Task, for: Mozart.Task.Subprocess do
  use Mozart.Task.Common

  def completable(subprocess), do: subprocess.complete

  def complete_task(task, state) do
    Logger.info("Complete subprocess task [#{task.name}][#{task.uid}]")
    data = Map.merge(task.data, state.data)

    Map.put(state, :data, data)
    |> update_completed_task_state(task, task.next)
    |> execute_process()
  end
end

defimpl Mozart.Task, for: Mozart.Task.Timer do
  use Mozart.Task.Common

  def completable(timer), do: timer.expired

  def complete_task(task, state) do
    Logger.info("Complete timer task [#{task.name}]")
    update_completed_task_state(state, task, task.next) |> execute_process()
  end
end

defimpl Mozart.Task, for: Mozart.Task.User do
  use Mozart.Task.Common

  def completable(user), do: user.complete

  def complete_task(_task, _state), do: raise "do not call"
end
