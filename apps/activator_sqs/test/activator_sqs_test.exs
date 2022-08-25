defmodule ActivatorSQSTest do
  use ExUnit.Case
  doctest ActivatorSQS

  test "greets the world" do
    assert ActivatorSQS.hello() == :world
  end
end
