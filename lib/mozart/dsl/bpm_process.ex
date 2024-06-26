defmodule Mozart.Dsl.BpmProcess do
  alias Mozart.Task.Script
  alias Mozart.Task.User
  alias Mozart.Task.Subprocess
  alias Mozart.Task.Service
  alias Mozart.Task.Rule
  alias Mozart.Task.Case
  alias Mozart.Data.ProcessModel

  defmacro __using__(_opts) do
    quote do
      import Mozart.Dsl.BpmProcess

      @tasks []
      @processes []
      @capture_subtasks false
      @subtasks []
      @subtask_sets []
      @before_compile Mozart.Dsl.BpmProcess
    end
  end

  defmacro defprocess(name, do: body) do
    quote do
      process = %ProcessModel{name: unquote(name)}
      unquote(body)
      tasks = set_next_tasks(@tasks)
      tasks = tasks ++ List.flatten(@subtask_sets)
      process = Map.put(process, :tasks, tasks)
      initial_task_name = Map.get(hd(tasks), :name)
      process = Map.put(process, :initial_task, initial_task_name)
      @processes [process | @processes]
      @tasks []
      @subtasks []
      @subtask_sets []
    end
  end

  def set_next_tasks([task]), do: [task]
  def set_next_tasks([task1, task2 | rest]) do
    task1 = Map.put(task1, :next, task2.name)
    [task1 | set_next_tasks([task2 | rest])]
  end

  defmacro insert_new_task(task) do
    quote do
      if @capture_subtasks do
        @subtasks @subtasks ++ [unquote(task)]
      else
        @tasks @tasks ++ [unquote(task)]
      end
    end
  end

  def parse_inputs(inputs_string) do
    Enum.map(String.split(inputs_string, ","), fn input -> String.to_atom(input) end)
  end

  def parse_user_groups(groups_string) do
    String.split(groups_string, ",")
  end

  defmacro case_task(name, cases) do
    quote do
      case_task = %Case{name: unquote(name), cases: unquote(cases)}
      insert_new_task(case_task)
    end
  end

  defmacro case_i(expr, do: tasks) do
    quote do
      @capture_subtasks true
      unquote(tasks)
      first = hd(@subtasks)
      @subtasks set_next_tasks(@subtasks)
      @subtask_sets [@subtasks | @subtask_sets]
      @subtasks []
      @capture_subtasks false
      %{expression: unquote(expr), next: first.name}
    end
  end

  defmacro rule_task(name, inputs: inputs, rule_table: rule_table) do
    quote do
      inputs = parse_inputs(unquote(inputs))
      rule_table = Tablex.new(unquote(rule_table))
      rule_task = %Rule{name: unquote(name), inputs: inputs, rule_table: rule_table}
      insert_new_task(rule_task)
    end
  end

  defmacro subprocess_task(name, model: subprocess_name) do
    quote do
      subprocess =
        %Subprocess{name: unquote(name), sub_process_model_name: unquote(subprocess_name)}

      insert_new_task(subprocess)
    end
  end

  defmacro service_task(name, module: mod, function: func, inputs: inputs) do
    quote do
      module = Module.concat([unquote(mod)])
      function = unquote(func)
      inputs = parse_inputs(unquote(inputs))

      service =
        %Service{name: unquote(name), module: module, function: function, inputs: inputs}

      insert_new_task(service)
    end
  end

  defmacro script_task(name, inputs: inputs, fn: service) do
    quote do
      script = %Script{
        name: unquote(name),
        inputs: unquote(inputs),
        function: unquote(service)
      }

      insert_new_task(script)
    end
  end

  defmacro user_task(name, groups: groups) do
    quote do
      groups = parse_user_groups(unquote(groups))
      user_task = %User{name: unquote(name), assigned_groups: groups}
      insert_new_task(user_task)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def get_processes, do: Enum.reverse(@processes)
      def get_process(name), do: Enum.find(@processes, fn p -> p.name == name end)

      def load_processes do
        process_names = Enum.map(@processes, fn p -> p.name end)
        IO.puts("loading processes[#{inspect(process_names)}]")
      end
    end
  end
end
