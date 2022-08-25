defmodule ActivatorHTTPTest do
  use ExUnit.Case
  doctest ActivatorHTTP

  test "greets the world" do
    assert ActivatorHTTP.hello() == :world
  end
end
