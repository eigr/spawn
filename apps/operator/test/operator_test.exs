defmodule OperatorTest do
  use ExUnit.Case
  doctest Operator

  test "greets the world" do
    assert Operator.hello() == :world
  end
end
