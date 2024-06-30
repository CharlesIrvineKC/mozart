defmodule Experiment do
  @moduledoc false
  defmacro get_function({:>, _, [{var1, _, _}, {var2, _, _}]}) do
    quote do
      fn data -> data[unquote(var1)] > data[unquote(var2)] end
    end
  end

  defmacro option_key_args(name, args) do
    quote do
      case unquote(args) do
        [a: a] -> {a, unquote(name)}
        [a: a, b: b] -> {a, b, unquote(name)}
      end
    end
  end
end
