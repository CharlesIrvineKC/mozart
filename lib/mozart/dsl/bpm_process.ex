defmodule Mozart.Dsl.BpmProcess do
  alias Mozart.Task.Script
  alias Mozart.Task.User
  alias Mozart.Task.Subprocess
  alias Mozart.Task.Service
  alias Mozart.Data.ProcessModel

  defmacro __using__(_opts) do
    quote do
      import Mozart.Dsl.BpmProcess

      @tasks []
      @processes []
      @before_compile Mozart.Dsl.BpmProcess
    end
  end

  defmacro defprocess(name, do: body) do
    quote do
      process = %ProcessModel{name: unquote(name)}
      tasks = unquote(body)
      process = Map.put(process, :tasks, Enum.reverse(@tasks))
      initial_task_name = Map.get(hd(@tasks), :name)
      process = Map.put(process, :initial_task, initial_task_name)
      @processes [process | @processes]
      @tasks []
    end
  end

  def insert_new_task(task, []), do: [task]
  def insert_new_task(task, [pre | rest]), do: [task, Map.put(pre, :next, task.name) | rest]

  def parse_inputs(inputs_string) do
    Enum.map(String.split(inputs_string, ","), fn input -> String.to_atom(input) end)
  end

  def parse_user_groups(groups_string) do
    String.split(groups_string, ",")
  end

  defmacro subprocess_task(name, model: subprocess_name) do
    quote do
      subprocess =
        %Subprocess{name: unquote(name), sub_process_model_name: unquote(subprocess_name)}
        @tasks insert_new_task(subprocess, @tasks)
    end
  end

  defmacro service_task(name, mod: mod, func: func, inputs: inputs) do
    quote do
      module = Module.concat([unquote(mod)])
      function = String.to_atom(unquote(func))
      inputs = parse_inputs(unquote(inputs))
      service =
        %Service{name: unquote(name), module: module, function: function, input_fields: inputs}

      @tasks insert_new_task(service, @tasks)
    end
  end

  defmacro script_task(name, inputs: inputs, fn: service) do
    quote do
      script = %Script{
        name: unquote(name),
        input_fields: unquote(inputs),
        function: unquote(service)
      }

      @tasks insert_new_task(script, @tasks)
    end
  end

  defmacro user_task(name, groups: groups) do
    quote do
      groups = parse_user_groups(unquote(groups))
      user_task = %User{name: unquote(name), assigned_groups: groups}
      @tasks insert_new_task(user_task, @tasks)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def get_processes, do: Enum.reverse(@processes)

      def load_processes do
        process_names = Enum.map(@processes, fn p -> p.name end)
        IO.puts("loading processes[#{inspect(process_names)}]")
      end
    end
  end
end
