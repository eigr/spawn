defmodule Controller.ActorHostControllerTest do
  use ExUnit.Case
  use Bonny.Axn.Test

  alias SpawnOperator.Controller.ActorHostController
  alias SpawnOperator.Test.IntegrationHelper

  import SpawnOperator.FactoryTest

  setup do
    conn = IntegrationHelper.conn()
    simple_host = build_simple_actor_host()

    [
      axn: axn(:add, resource: simple_host, conn: conn)
    ]
  end

  @tag :integration
  test "registers descending resources", %{axn: axn} do
    descendants =
      axn
      |> ActorHostController.call(nil)
      |> descendants()

    assert length(descendants) > 0
  end
end
