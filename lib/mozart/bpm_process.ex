defmodule Mozart.BpmProcess do
  @moduledoc """
  This module implements a BPM Domain Specific Language (DSL) framework. To use, insert
  **use Mozart.BpmProcess** into your modules.

  ```elixir
  defmodule Mozart.MyBpmApplication do
    use Mozart.BpmProcess

    # Your process model definitions
  end
  ```
  """
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
  alias Mozart.Task.Prototype
  alias Mozart.Task.Repeat
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
  more task functions.

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

  @doc """
  Used to define parallel execution paths. Arguments are the task name
  and a list of routes.

  ```
  defprocess "two parallel routes process" do
    parallel_task("a parallel task", [
      route do
        user_task("1", groups: "admin")
        user_task("2", groups: "admin")
      end,
      route do
        user_task("3", groups: "admin")
        user_task("4", groups: "admin")
      end
    ])
  end
  ```
  """
  defmacro parallel_task(name, routes) do
    quote do
      task = %Parallel{name: unquote(name), multi_next: unquote(routes)}
      insert_new_task(task)
    end
  end

  @doc """
  Used to define one of many parallel execution paths within a parallel task. Arguments are a task name a block of tasks.

  ```
  defprocess "two parallel routes process" do
    parallel_task("a parallel task", [
      route do
        user_task("1", groups: "admin")
        user_task("2", groups: "admin")
      end,
      route do
        user_task("3", groups: "admin")
        user_task("4", groups: "admin")
      end
    ])
  end
  ```
  """
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

  defmacro repeat_task(name, condition, do: tasks) do
    quote do
      r_task = %Repeat{name: unquote(name), condition: unquote(condition)}
      insert_new_task(r_task)
      @capture_subtasks true
      unquote(tasks)
      @subtasks set_next_tasks(@subtasks)
      first = List.first(@subtasks)
      last = List.last(@subtasks)
      r_task = Map.put(r_task, :first, first.name) |> Map.put(:last, last.name)
      @tasks Enum.map(@tasks, fn t -> if t.name == unquote(name), do: r_task, else: t end)
      @subtask_sets [@subtasks | @subtask_sets]
      @subtasks []
      @capture_subtasks false
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

  @doc """
  Used to select one of many execution paths. Arguments are a task name and a list of cases.

  ```
  defprocess "two case process" do
    case_task("yes or no", [
      case_i &ME.x_less_than_y/1 do
        user_task("1", groups: "admin")
        user_task("2", groups: "admin")
      end,
      case_i &ME.x_greater_or_equal_y/1 do
        user_task("3", groups: "admin")
        user_task("4", groups: "admin")
      end
    ])
  end
  ```
  """
  defmacro case_task(name, cases) do
    quote do
      case_task = %Case{name: unquote(name), cases: unquote(cases)}
      insert_new_task(case_task)
    end
  end

  @doc """
  Used to specify one of many alternate execution paths. Arguments are a task name
  and a block of tasks.

  ```
  defprocess "two case process" do
    case_task("yes or no", [
      case_i &ME.x_less_than_y/1 do
        user_task("1", groups: "admin")
        user_task("2", groups: "admin")
      end,
      case_i &ME.x_greater_or_equal_y/1 do
        user_task("3", groups: "admin")
        user_task("4", groups: "admin")
      end
    ])
  end
  ```
  """
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

  @doc """
  Used to specify a timed delay in an execution path. Arguments are a task name and
  a duration in milliseconds.

  ```
  defprocess "two timer task process" do
    timer_task("one second timer task", duration: 1000)
    timer_task("two second timer task", duration: 2000)
  end
  ```
  """
  defmacro timer_task(name, duration: duration) do
    quote do
      task = %Timer{name: unquote(name), timer_duration: unquote(duration)}
      insert_new_task(task)
    end
  end

  @doc """
  Used to specify a task that has no behavior. Used for prototyping. Has a single
  name argument

  ```
  defprocess "two prototype task process" do
    prototype_task("prototype task 1")
    prototype_task("prototype task 2")
  end
  ```
  """
  defmacro prototype_task(name) do
    quote do
      task = %Prototype{name: unquote(name)}
      insert_new_task(task)
    end
  end

  @doc """
  Used to set data properties based on evaluation of rules in a rule table. Arguments
  are a task name, a set of inputs and a rule table.

  ```
  rule_table = \"""
  F     income      || status
  1     > 50000     || approved
  2     <= 49999    || declined
  \"""

  defprocess "single rule task process" do
    rule_task("loan decision", inputs: "income", rule_table: rule_table)
  end
  ```
  """
  defmacro rule_task(name, inputs: inputs, rule_table: rule_table) do
    quote do
      inputs = parse_inputs(unquote(inputs))
      rule_table = Tablex.new(unquote(rule_table))
      rule_task = %Rule{name: unquote(name), inputs: inputs, rule_table: rule_table}
      insert_new_task(rule_task)
    end
  end

  @doc """
  Used to specify a task completed by spawning and completing a subprocess. Arguments
  are a task name and the name of the subprocess model.

  ```
  defprocess "subprocess task process" do
    subprocess_task("subprocess task", model: "two service tasks")
  end
  ```
  """
  defmacro subprocess_task(name, model: subprocess_name) do
    quote do
      subprocess =
        %Subprocess{name: unquote(name), sub_process_model_name: unquote(subprocess_name)}

      insert_new_task(subprocess)
    end
  end

  @doc """
  A task that send a PubSub event to a receiving receive_task. Arguments are a task name
  and a PubSub message.

  ```
  defprocess "send barrower income process" do
    send_task("send barrower income", message: {:barrower_income, 100_000})
  end
  ```
  """
  defmacro send_task(name, message: message) do
    quote do
      task = %Send{name: unquote(name), message: unquote(message)}
      insert_new_task(task)
    end
  end

  @doc """
  Used to specify a task completed by calling an Elixir function. Arguments are
  a task name, a set of comma delitmited inputs a captured Elixir function.

  ```
  def square(data) do
    Map.put(data, :square, data.x * data.x)
  end

  defprocess "one service task process" do
    service_task("a service task", function: &MyBpmApplication.square/1, inputs: "x")
  end
  ```
  """
  defmacro service_task(name, function: func, inputs: inputs) do
    quote do
      function = unquote(func)
      inputs = parse_inputs(unquote(inputs))

      service =
        %Service{name: unquote(name), function: function, inputs: inputs}

      insert_new_task(service)
    end
  end

  @doc """
  Used to suspend an execution path until receiving a specified PubSub event. Arguemnts
  are a task name and captured function

  ```
  def receive_loan_income(msg) do
    case msg do
      {:barrower_income, income} -> %{barrower_income: income}
      _ -> nil
    end
  end

  defprocess "receive barrower income process" do
    receive_task("receive barrower income", selector: &MyBpmApplication.receive_loan_income/1)
  end
  ```
  """
  defmacro receive_task(name, selector: function) do
    quote do
      task = %Receive{name: unquote(name), message_selector: unquote(function)}

      insert_new_task(task)
    end
  end

  @doc """
  Used to specify a task performed by a user belonging to a specified workgroup. Arguments are
  a task name and a set of comma delimited workgroups.

  ```
  defprocess "single user task process" do
    user_task("add one to x", groups: "admin,customer_service")
  end
  ```
  """
  defmacro user_task(name, args) do
    quote do
      {groups, inputs} =
        case unquote(args) do
          [groups: groups, inputs: inputs] ->
            groups = parse_user_groups(groups)
            inputs = parse_inputs(inputs)
            {groups, inputs}

          [groups: groups] ->
            groups = parse_user_groups(groups)
            {groups, nil}
        end

      user_task = %User{name: unquote(name), assigned_groups: groups, inputs: inputs}
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
