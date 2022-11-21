defmodule Actors.ActorRegistryTest do
  use Actors.DataCase, async: false

  alias Eigr.Functions.Protocol.ActorInvocationResponse
  alias Eigr.Functions.Protocol.RegistrationResponse

  setup do
    actor_name = "actor_registry_test_two_nodes"
    actor = build_actor(name: actor_name)
    actor_entry = build_actor_entry(name: actor_name, actor: actor)
    registry = build_registry_with_actors(actors: actor_entry)
    system = build_system(name: "actor_registry_test_two_nodes_sys", registry: registry)
    request = build_registration_request(actor_system: system)

    %{request: request, actor_name: actor_name}
  end

  test "register actors for a system in two nodes", ctx do
    %{request: request} = ctx

    peer_node_name = :"spawn_actors_node@127.0.0.1"

    assert :ok == Spawn.Cluster.StateHandoff.join(peer_node_name)

    assert {:ok, %RegistrationResponse{}} =
             Spawn.NodeHelper.rpc(peer_node_name, Actors, :register, [
               request
             ])

    # actor registered and present in the other node
    assert %{"actor_registry_test_two_nodes" => [%{node: ^peer_node_name}]} =
             Spawn.NodeHelper.rpc(peer_node_name, Actors.ActorsHelper, :registered_actors, [])

    # also present in self node
    assert %{"actor_registry_test_two_nodes" => [%{node: ^peer_node_name}]} =
             Actors.ActorsHelper.registered_actors()

    Actors.register(request)

    # present in both nodes too
    assert %{"actor_registry_test_two_nodes" => actors} = Actors.ActorsHelper.registered_actors()
    peer_node_name in Enum.map(actors, & &1.node)
    :"spawn@127.0.0.1" in Enum.map(actors, & &1.node)

    # present in both nodes calling in the other node
    assert %{"actor_registry_test_two_nodes" => actors} =
             Spawn.NodeHelper.rpc(peer_node_name, Actors.ActorsHelper, :registered_actors, [])

    peer_node_name in Enum.map(actors, & &1.node)
    :"spawn@127.0.0.1" in Enum.map(actors, & &1.node)

    Spawn.Cluster.StateHandoff.clean(peer_node_name)

    # now present only in current node
    assert %{"actor_registry_test_two_nodes" => actors} = Actors.ActorsHelper.registered_actors()
    assert [:"spawn@127.0.0.1"] == Enum.map(actors, & &1.node)
  end
end
