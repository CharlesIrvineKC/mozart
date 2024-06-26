defmodule Experiment do
  defmacro get_function({:>, _, [{var1, _, _}, {var2, _, _}]}) do
    quote do
      fn data -> data[unquote(var1)] > data[unquote(var2)] end
    end
  end
end
