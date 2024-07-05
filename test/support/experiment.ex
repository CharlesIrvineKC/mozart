defmodule Experiment do

  defmacro foo(name, opts, do: block) do
    quote do
      [x: x, y: y] = unquote(opts)
      IO.puts unquote(name)
      x + y + unquote(block)
    end
  end

end
