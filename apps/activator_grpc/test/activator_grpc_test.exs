defmodule ActivatorGRPCTest do
  use ExUnit.Case
  doctest ActivatorGRPC

  test "greets the world" do
    assert ActivatorGRPC.hello() == :world
  end
end
