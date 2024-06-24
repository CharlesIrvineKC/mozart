defmodule Mozart.Dsl.BpmProcess do
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
      process = Map.put(process, :tasks, @tasks)
      @processes [process | @processes]
      @tasks []
    end
  end

  defmacro call_service(name) do
    quote do
      @tasks [%Service{name: unquote(name)} | @tasks]
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def get_processes, do: @processes
    end
  end
end
