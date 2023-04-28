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

    assert {:ok, %RegistrationResponse{}} =
             Spawn.NodeHelper.rpc(peer_node_name, Actors, :register, [
               request
             ])

    # actor registered and present in the other node
    assert %{^peer_node_name => [%{"actor_registry_test_two_nodes" => [_ | _]}]} =
             Spawn.NodeHelper.rpc(peer_node_name, Actors.ActorsHelper, :registered_actors, [])

    # also present in self node
    assert %{^peer_node_name => [%{"actor_registry_test_two_nodes" => [_ | _]}]} =
             Actors.ActorsHelper.registered_actors()

    Actors.register(request)

    # present in both nodes too
    registered = Actors.ActorsHelper.registered_actors()
    assert %{:"spawn@127.0.0.1" => %{"actor_registry_test_two_nodes" => [_ | _]}} = registered
    assert %{^peer_node_name => %{"actor_registry_test_two_nodes" => [_ | _]}} = registered

    # present in both nodes calling in the other node
    registered = Spawn.NodeHelper.rpc(peer_node_name, Actors.ActorsHelper, :registered_actors, [])
    assert %{:"spawn@127.0.0.1" => %{"actor_registry_test_two_nodes" => [_ | _]}} = registered
    assert %{^peer_node_name => %{"actor_registry_test_two_nodes" => [_ | _]}} = registered

    Spawn.Cluster.StateHandoff.clean(peer_node_name)

    registered = Actors.ActorsHelper.registered_actors()

    # now present only in current node
    assert %{:"spawn@127.0.0.1" => %{"actor_registry_test_two_nodes" => [_ | _]}} = registered

    refute %{^peer_node_name => %{"actor_registry_test_two_nodes" => [_ | _]}} = registered
  end
end
