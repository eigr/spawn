defmodule Controller.ActorHostControllerTest do
  use ExUnit.Case
  use Bonny.Axn.Test

  alias SpawnOperator.Controller.ActorHostController
  # alias SpawnOperator.Handler.ActorHostHandler
  import SpawnOperator.FactoryTest

  setup do
    simple_host = build_simple_actor_host()

    [
      axn: axn(:add, resource: simple_host, conn: %K8s.Conn{})
    ]
  end

  test "registers descending resources", %{axn: axn} do
    assert [] =
             axn
             |> ActorHostController.call(nil)
             |> descendants()
             |> IO.inspect(label: "Descending resources")
  end

  # test "registers a success event", %{axn: axn} do
  #  assert [event] = axn |> ActorHostController.call(nil) |> events()
  #  assert :Normal == event.event_type
  # end
end
