defmodule SampleFunctions do
  @moduledoc false
  def square(data) do
    Map.put(data, :square, data.x * data.x)
  end
end
