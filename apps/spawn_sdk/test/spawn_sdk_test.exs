defmodule SpawnSdkTest do
  use ExUnit.Case
  doctest SpawnSdk

  test "greets the world" do
    assert SpawnSdk.hello() == :world
  end
end
