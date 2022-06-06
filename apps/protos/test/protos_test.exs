defmodule ProtosTest do
  use ExUnit.Case
  doctest Protos

  test "greets the world" do
    assert Protos.hello() == :world
  end
end
