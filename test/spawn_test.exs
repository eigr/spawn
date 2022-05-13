defmodule SpawnTest do
  use ExUnit.Case
  doctest Spawn

  test "greets the world" do
    assert Spawn.hello() == :world
  end
end
