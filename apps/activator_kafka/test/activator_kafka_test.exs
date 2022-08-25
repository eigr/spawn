defmodule ActivatorKafkaTest do
  use ExUnit.Case
  doctest ActivatorKafka

  test "greets the world" do
    assert ActivatorKafka.hello() == :world
  end
end
