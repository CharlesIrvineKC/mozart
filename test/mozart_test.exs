defmodule MozartTest do
  use ExUnit.Case
  doctest Mozart

  test "greets the world" do
    assert Mozart.hello() == :world
  end
end
