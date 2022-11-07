defmodule Controller.ActorHostControllerTest do
  use ExUnit.Case
  use Bonny.Axn.Test

  alias SpawnOperator.Controller.ActorHostController

  import SpawnOperator.FactoryTest

  setup do
    simple_host = build_simple_actor_host()

    [
      axn: axn(:add, resource: simple_host, conn: %K8s.Conn{})
    ]
  end

  @tag :skip
  test "registers descending resources", %{axn: axn} do
    descendants =
      axn
      |> ActorHostController.call(nil)
      |> descendants()
      |> IO.inspect(label: "Descending resources")

    assert length(descendants) > 0
  end
end
