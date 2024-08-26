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

  alias Mozart.Task.Conditional
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
  alias Mozart.Task.Reroute
  alias Mozart.Task.Conditional

  alias Mozart.Type.Choice
  alias Mozart.Type.MultiChoice
  alias Mozart.Type.Number
  alias Mozart.Type.Confirm

  alias Mozart.Event.TaskExit

  alias Mozart.Data.ProcessModel
  alias Mozart.Data.BpmApplication

  alias Mozart.ProcessService

  defmacro __using__(_opts) do
    quote do
      import Mozart.BpmProcess

      # Holds the tasks in a single process definition
      @tasks []
      @processes []
      @capture_subtasks false
      # A stack used to hold the subtasks of a single task
      @subtasks []
      # Holds all task subtasks. When compilation is complete list is flattened
      @subtask_sets []
      @events %{}
      @event_tasks []
      @route_task_names []
      @cases []
      @event_task_process_map %{}
      @bpm_applications []
      @types []
      @before_compile Mozart.BpmProcess
    end
  end

  @doc """
  Used to define a BPM application. An BPM application is used to identity a single
  business process implemented in a Elixir module. It's purpose is to facilitate external tool
  integration. A single Elixir module might have zero or more such definitions. It's parameters
  are as follows:
  * **name**: A user level name for the business process.
  * **name**: The name of the top level process defintion.
  * **data**: A comma separated list of input parameters that the busines process should be
  initialized with.

  Example:
  def_bpm_application("Home Loan Process", main: "Home Loan", data: "Customer Name,Income,Debt")
  """
  defmacro def_bpm_application(name, main: main, data: data, bk_prefix: prefix) do
    quote do
      data = parse_params(unquote(data))
      prefix = parse_params(unquote(prefix))

      bpm_application = %BpmApplication{
        name: unquote(name),
        main: unquote(main),
        data: data,
        bk_prefix: prefix
      }

      @bpm_applications [bpm_application | @bpm_applications]
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
      IO.inspect(tasks, label: "*** tasks **")
      tasks = tasks ++ List.flatten(@subtask_sets)
      IO.inspect(@subtask_sets, label: "** subtask sets **")
      check_for_duplicates("task", tasks)
      process = Map.put(process, :tasks, tasks)
      initial_task_name = Map.get(hd(tasks), :name)
      process = Map.put(process, :initial_task, initial_task_name)
      @processes [process | @processes]
      check_for_duplicates("process", @processes)
      @tasks []
      @subtasks []
      @subtask_sets []
    end
  end

  @doc """
  Used to associate a single choice, enumerated type for a process data parameter. It's
  purpose is to facilitate interation with external tools, e.g. GUIs.

  Example:

  def_choice_type("Pre Approval", choices: "Approved, Declined")
  """
  defmacro def_choice_type(param_name, choices: choices) do
    quote do
      choices = parse_params(unquote(choices))
      choice = %Choice{param_name: unquote(param_name), choices: choices}
      @types [choice | @types]
    end
  end

  @doc """
  Used to associate a multiple choice, enumerated type for a process data parameter. It's
  purpose is to facilitate interation with external tools, e.g. GUIs.

  Example:

  def_multi_choice_type("multi choice param", choices: "foo,bar,foobar")
  """
  defmacro def_multi_choice_type(param_name, choices: choices) do
    quote do
      choices = parse_params(unquote(choices))
      choice = %MultiChoice{param_name: unquote(param_name), choices: choices}
      @types [choice | @types]
    end
  end

  @doc """
  Used to associate a numerical type for a process data parameter. It's
  purpose is to facilitate interation with external tools, e.g. GUIs.

  Example:

  def_number_type("number param", min: 0, max: 5)
  """
  defmacro def_number_type(param_name, options) do
    quote do
      options = unquote(options)
      min = Enum.find_value(options, fn {k, v} -> if k == :min, do: v end)
      max = Enum.find_value(options, fn {k, v} -> if k == :max, do: v end)
      num_type = %Number{param_name: unquote(param_name), min: min, max: max}
      @types [num_type | @types]
    end
  end

  @doc """
  Used to associate a confirmational type for a process data parameter. It's
  purpose is to facilitate interation with external tools, e.g. GUIs. Intended
  to be associated with a check box that the user must check to complete a task.

  Example:

  def_confirm_type("confirm param")
  """
  defmacro def_confirm_type(param_name) do
    quote do
      confirm_type = %Confirm{param_name: unquote(param_name)}
      @types [confirm_type | @types]
    end
  end

  @doc """
  Used to implement a business process event. Arguments are:
  * the name of the event
  * **process**: the name of the process that the event will act upon
  * **exit_task**: the name of the task to be exited
  * **selector**: a function that matches on the target event
  * **do**: one or more tasks to be executed when the target task is exited.
  ```
  defevent "exit loan decision 1",
    process: "exit a user task 1",
    exit_task: "user task 1",
    selector: :event_selector do
      prototype_task("event 1 prototype task 1")
      prototype_task("event 1 prototype task 2")
  end
  ```
  """
  defmacro defevent(name, options, do: tasks) do
    quote do
      options = unquote(options)
      process = Keyword.get(options, :process)
      exit_task = Keyword.get(options, :exit_task)
      selector = Keyword.get(options, :selector)
      module = Keyword.get(options, :module) || __MODULE__

      event = %TaskExit{
        name: unquote(name),
        exit_task: exit_task,
        selector: selector,
        module: module
      }

      new_subtask_context()
      unquote(tasks)
      order_subtasks()
      first = hd(get_subtasks())
      event = Map.put(event, :next, Map.get(hd(get_subtasks()), :name))
      @event_task_process_map Map.put(@event_task_process_map, process, get_subtasks())
      @events Map.put(@events, process, event)
      @tasks []
      @subtasks []
      @subtask_sets []
      @capture_subtasks false
    end
  end

  @doc false
  def check_for_duplicates(type, tasks) do
    task_names = Enum.map(tasks, fn t -> t.name end)
    dup_task_names = Enum.uniq(task_names -- Enum.uniq(task_names))
    if dup_task_names != [], do: raise("Duplicate #{type} names: #{inspect(dup_task_names)}")
  end

  @doc false
  def set_next_tasks([task]), do: [task]

  def set_next_tasks([task1, task2 | rest]) do
    task1 = Map.put(task1, :next, task2.name)
    [task1 | set_next_tasks([task2 | rest])]
  end

  @doc """
  Used to define parallel execution paths. Arguments are the task name
  and a list of routes.

  ```
  defprocess "two parallel routes process" do
    parallel_task "a parallel task" do
      route do
        user_task("1", groups: "admin")
        user_task("2", groups: "admin")
      end
      route do
        user_task("3", groups: "admin")
        user_task("4", groups: "admin")
      end
    end
  end
  ```
  """
  defmacro parallel_task(name, do: routes) do
    quote do
      task = %Parallel{name: unquote(name)}
      unquote(routes)
      task = Map.put(task, :multi_next, @route_task_names)
      insert_new_task(task)
      @route_task_names []
    end
  end

  @doc false
  defmacro route(do: tasks) do
    quote do
      new_subtask_context()
      unquote(tasks)
      first = hd(get_subtasks())
      order_subtasks()
      @route_task_names @route_task_names ++ [first.name]
      reset_subtasks()
    end
  end

  @doc """
  Used to define a task that executes only when a condition (function)
  evaluates to true (a truthy value). When  the condition evaluates to
  false, execution proceeds directly to the next task.

  Example:

  ```
  defprocess "process with conditional task" do
    prototype_task("fast initial credit check")
    conditional_task "additional credit check", condition: :initial_check_inconclusive do
      prototype_task("extensive credit check")
    end
    prototype_task("report credit check results")
  end
  ```
  """
  defmacro conditional_task(name, options, do: tasks) do
    quote do
      options = unquote(options)
      condition = Keyword.get(options, :condition)
      module = Keyword.get(options, :module) || __MODULE__
      c_task = %Conditional{name: unquote(name), condition: condition, module: module}
      insert_new_task(c_task)
      new_subtask_context()
      unquote(tasks)
      order_subtasks()
      first = List.first(get_subtasks())
      last = List.last(get_subtasks())
      c_task = Map.put(c_task, :first, first.name) |> Map.put(:last, last.name)
      @tasks Enum.map(@tasks, fn t -> if t.name == unquote(name), do: c_task, else: t end)
      reset_subtasks()
    end
  end

  @doc """
  Used to a sequence of tasks that repeat as long as a condition evaluates to
  a truthy value.

  Example:
  ```
  defprocess "account overdue process" do
    repeat_task "notify customer", condition: :third_notice_sent do
      service_task("send overdue notice", function: :record_notifiction_sent)
    end
  end
  ```
  """
  defmacro repeat_task(name, options, do: tasks) do
    quote do
      options = unquote(options)
      condition = Keyword.get(options, :condition)
      module = Keyword.get(options, :module) || __MODULE__
      r_task = %Repeat{name: unquote(name), condition: condition, module: module}
      insert_new_task(r_task)
      new_subtask_context()
      unquote(tasks)
      order_subtasks()
      first = List.first(get_subtasks())
      last = List.last(get_subtasks())
      r_task = Map.put(r_task, :first, first.name) |> Map.put(:last, last.name)
      @tasks Enum.map(@tasks, fn t -> if t.name == unquote(name), do: r_task, else: t end)
      reset_subtasks()
    end
  end

  defmacro order_subtasks() do
    quote do
      ordered_subtasks = set_next_tasks(get_subtasks())
      set_subtasks(ordered_subtasks)
    end
  end

  defmacro set_subtasks(subtasks) do
    quote do
      [_first | rest] = @subtasks
      @subtasks [unquote(subtasks) | rest]
    end
  end

  # @doc false
  # defmacro insert_new_task(task) do
  #   quote do
  #     if @capture_subtasks do
  #       @subtasks @subtasks ++ [unquote(task)]
  #     else
  #       @tasks @tasks ++ [unquote(task)]
  #     end
  #   end
  # end

  defmacro insert_new_task(task) do
    quote do
      if @subtasks == [] do
        @tasks @tasks ++ [unquote(task)]
      else
        new_subtasks = get_subtasks() ++ [unquote(task)]
        set_subtasks(new_subtasks)
      end
    end
  end

  # @doc false
  # defmacro insert_new_task(task) do
  #   quote do
  #     if @capture_subtasks do
  #       @subtasks @subtasks ++ [unquote(task)]
  #     else
  #       @tasks @tasks ++ [unquote(task)]
  #     end
  #   end
  # end

  defmacro get_subtasks() do
    quote do
      hd(@subtasks)
    end
  end

  defmacro new_subtask_context() do
    quote do
      # @capture_subtasks true
      subtasks_push()
    end
  end

  defmacro reset_subtasks() do
    quote do
      @subtask_sets [get_subtasks() | @subtask_sets]
      # @subtasks []
      # @capture_subtasks false
      subtasks_pop()
    end
  end

  defmacro subtasks_push() do
    quote do
      @subtasks [[] | @subtasks]
    end
  end

  defmacro subtasks_pop() do
    quote do
      [_first | rest] = @subtasks
      @subtasks rest
    end
  end

  @doc false
  def parse_params(inputs_string) do
    String.split(inputs_string, ",") |> Enum.map(fn s -> String.trim(s) end)
  end

  @doc false
  def parse_user_groups(groups_string) do
    String.split(groups_string, ",") |> Enum.map(fn s -> String.trim(s) end)
  end

  @doc """
  Used to reroute a process flow off the typical execution path (off the 'happy path').

  Example:
  ```
  defprocess "act on one of multiple events" do
    prototype_task("create order")
    receive_task("receive payment details", selector: :receive_payment_details)
    reroute_task "payment period expired", condition: :payment_period_expired do
      prototype_task("cancel order due to timeout")
    end
    reroute_task "order canceled", condition: :order_canceled do
      prototype_task("cancel order due to order cancelation")
    end
    prototype_task("process payment")
  end
  ```
  """
  defmacro reroute_task(name, options, do: tasks) do
    quote do
      options = unquote(options)
      condition = Keyword.get(options, :condition)
      module = Keyword.get(options, :module) || __MODULE__
      name = unquote(name)
      reroute = %Reroute{name: name, condition: condition, module: module}
      insert_new_task(reroute)
      new_subtask_context()
      tasks = unquote(tasks)
      first = hd(get_subtasks())

      @tasks Enum.map(
               @tasks,
               fn t ->
                 if t.name == name, do: Map.put(t, :reroute_first, first.name), else: t
               end
             )
      order_subtasks()
      reset_subtasks()
    end
  end

  @doc """
  Used to select one of many execution paths. Arguments are a task name and a list of cases.

  ```
  defprocess "two case process" do
    case_task "yes or no" do
      case_i :x_less_than_y do
        user_task("1", groups: "admin")
        user_task("2", groups: "admin")
      end
      case_i :x_greater_or_equal_y do
        user_task("3", groups: "admin")
        user_task("4", groups: "admin")
      end
    end
  end
  ```
  """
  defmacro case_task(name, do: cases) do
    quote do
      task = %Case{name: unquote(name)}
      unquote(cases)
      task = Map.put(task, :cases, @cases)
      insert_new_task(task)
      @cases []
    end
  end

  @doc """
  Used to specify one of many alternate execution paths. The first argument is either
  a captured function or an atom corresponding to local function of arity 1. The second
  argument is a block of tasks.

  ```
  defprocess "two case process" do
    case_task "yes or no" do
      case_i :x_less_than_y do
        user_task("1", groups: "admin")
        user_task("2", groups: "admin")
      end
      case_i :x_greater_or_equal_y do
        user_task("3", groups: "admin")
        user_task("4", groups: "admin")
      end
    end
  end
  ```
  """
  defmacro case_i(expr, do: tasks) do
    quote do
      new_subtask_context()
      unquote(tasks)
      expr = unquote(expr)
      expr = if is_atom(expr), do: Function.capture(__MODULE__, expr, 1), else: expr
      first = hd(get_subtasks())
      order_subtasks()
      case = %{expression: expr, next: first.name}
      @cases @cases ++ [case]
      reset_subtasks()
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
  defmacro prototype_task(name, data \\ nil) do
    quote do
      data = unquote(data)
      name = unquote(name)
      task = if data, do: %Prototype{name: name, data: data}, else: %Prototype{name: name}
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
      inputs = parse_params(unquote(inputs))
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
        %Subprocess{name: unquote(name), model: unquote(subprocess_name)}

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
    service_task("a service task", function: :square, inputs: "x")
  end
  ```
  """
  defmacro service_task(name, options) do
    quote do
      options = unquote(options)
      function = Keyword.get(options, :function)
      module = Keyword.get(options, :module) || __MODULE__
      inputs = Keyword.get(options, :inputs)
      inputs = parse_params(inputs)

      service =
        %Service{name: unquote(name), function: function, module: module, inputs: inputs}

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
    receive_task("receive barrower income", selector: :receive_loan_income)
  end
  ```
  """
  defmacro receive_task(name, options) do
    quote do
      options = unquote(options)
      selector = Keyword.get(options, :selector)
      module = Keyword.get(options, :module) || __MODULE__
      task = %Receive{name: unquote(name), selector: selector, module: module}

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
      {groups, inputs, outputs} =
        case unquote(args) do
          [groups: groups, inputs: inputs, outputs: outputs] ->
            groups = parse_user_groups(groups)
            inputs = parse_params(inputs)
            outputs = parse_params(outputs)
            {groups, inputs, outputs}

          [groups: groups, outputs: outputs] ->
            groups = parse_user_groups(groups)
            outputs = parse_params(outputs)
            {groups, nil, outputs}
        end

      user_task = %User{
        name: unquote(name),
        assigned_groups: groups,
        inputs: inputs,
        outputs: outputs
      }

      insert_new_task(user_task)
    end
  end

  @doc false
  def merge_event_tasks_to_process(event_task_process_map, processes) do
    process_name_task_list = Map.to_list(event_task_process_map)
    merge_recursive(process_name_task_list, processes)
  end

  @doc false
  def merge_recursive([], processes), do: processes

  def merge_recursive([{process_name, tasks} | rest], processes) do
    merge_recursive(
      rest,
      Enum.map(
        processes,
        fn p ->
          if process_name == p.name do
            tasks = p.tasks ++ tasks
            Map.put(p, :tasks, tasks)
          else
            p
          end
        end
      )
    )
  end

  @doc false
  def assign_events_to_processes([], processes), do: processes

  def assign_events_to_processes([{pname, event} | rest], processes) do
    assign_events_to_processes(
      rest,
      Enum.map(processes, fn p ->
        if pname == p.name do
          events = [event | p.events]
          Map.put(p, :events, events)
        else
          p
        end
      end)
    )
  end

  defmacro __before_compile__(_env) do
    quote do
      if @event_task_process_map != %{} do
        @processes merge_event_tasks_to_process(@event_task_process_map, @processes)
        @processes assign_events_to_processes(Map.to_list(@events), @processes)
      end

      # def get_bpm_application, do: @bpm_applications
      def get_processes, do: Enum.reverse(@processes)
      def get_process(name), do: Enum.find(@processes, fn p -> p.name == name end)

      def load() do
        ProcessService.load_process_models(get_processes())
        ProcessService.load_bpm_applications(@bpm_applications)
        ProcessService.load_types(@types)
      end

      def get_events, do: Map.to_list(@events)
    end
  end
end
