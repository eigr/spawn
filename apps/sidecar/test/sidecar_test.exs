defmodule SidecarTest do
  use ExUnit.Case
  doctest Sidecar

  test "greets the world" do
    assert Sidecar.hello() == :world
  end
end
