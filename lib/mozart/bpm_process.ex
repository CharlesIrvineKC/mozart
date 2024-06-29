defmodule Mozart.BpmProcess do
  alias Mozart.Task.Service
  alias Mozart.Task.User
  alias Mozart.Task.Subprocess
  alias Mozart.Task.Parallel
  alias Mozart.Task.Service
  alias Mozart.Task.Rule
  alias Mozart.Task.Case
  alias Mozart.Task.Receive
  alias Mozart.Task.Send
  alias Mozart.Task.Timer
  alias Mozart.Data.ProcessModel

  defmacro __using__(_opts) do
    quote do
      import Mozart.BpmProcess

      @tasks []
      @processes []
      @capture_subtasks false
      @subtasks []
      @subtask_sets []
      @before_compile Mozart.BpmProcess
    end
  end

  @doc """
  Used to implement a business process model. Arguments are a name followed by one or
  more task functions. Example:

  ```
  defprocess "two timer task process" do
    timer_task("one second timer task", duration: 1000)
    timer_task("two second timer task", duration: 2000)
  end
  ```
  """
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

  @doc false
  def set_next_tasks([task]), do: [task]
  def set_next_tasks([task1, task2 | rest]) do
    task1 = Map.put(task1, :next, task2.name)
    [task1 | set_next_tasks([task2 | rest])]
  end

  @doc false
  defmacro insert_new_task(task) do
    quote do
      if @capture_subtasks do
        @subtasks @subtasks ++ [unquote(task)]
      else
        @tasks @tasks ++ [unquote(task)]
      end
    end
  end

  defmacro parallel_task(name, routes) do
    quote do
      task = %Parallel{name: unquote(name), multi_next: unquote(routes)}
      insert_new_task(task)
    end
  end

  defmacro route(do: tasks) do
    quote do
      @capture_subtasks true
      unquote(tasks)
      first = hd(@subtasks)
      @subtasks set_next_tasks(@subtasks)
      @subtask_sets [@subtasks | @subtask_sets]
      @subtasks []
      @capture_subtasks false
      first.name
    end
  end

  @doc false
  def parse_inputs(inputs_string) do
    Enum.map(String.split(inputs_string, ","), fn input -> String.to_atom(input) end)
  end

  @doc false
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

  defmacro timer_task(name, duration: duration) do
    quote do
      task = %Timer{name: unquote(name), timer_duration: unquote(duration)}
      insert_new_task(task)
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

  defmacro send_task(name, message: message) do
    quote do
      task = %Send{name: unquote(name), message: unquote(message)}
      insert_new_task(task)
    end
  end

  defmacro service_task(name, function: func, inputs: inputs) do
    quote do
      function = unquote(func)
      inputs = parse_inputs(unquote(inputs))

      service =
        %Service{name: unquote(name), function: function, inputs: inputs}

      insert_new_task(service)
    end
  end

  defmacro receive_task(name, selector: function) do
    quote do
      task = %Receive{name: unquote(name), message_selector: unquote(function)}

      insert_new_task(task)
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
