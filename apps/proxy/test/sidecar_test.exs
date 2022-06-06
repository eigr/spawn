defmodule SidecarTest do
  use ExUnit.Case
  doctest Sidecar

  test "greets the world" do
    assert Proxy.hello() == :world
  end
end
