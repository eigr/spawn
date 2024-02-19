defmodule Actors.ActorRegistryTest do
  use Actors.DataCase, async: false

  alias Actors.Registry.ActorRegistry
  alias Eigr.Functions.Protocol.RegistrationResponse

  setup do
    actor_name = "actor_registry_test_two_nodes"
    system = "spawn-system"
    actor = build_actor(name: actor_name, system: system)
    actor_entry = build_actor_entry(name: actor_name, actor: actor)
    registry = build_registry_with_actors(actors: actor_entry)
    system = build_system(name: system, registry: registry)
    request = build_registration_request(actor_system: system)

    %{request: request, actor_name: actor_name, actor_id: actor.id}
  end

  test "register the same actor for a system in two different nodes", ctx do
    %{request: request, actor_id: actor_id} = ctx

    peer_node_name = :"spawn_actors_node@127.0.0.1"

    assert {:ok, %RegistrationResponse{}} =
             Spawn.NodeHelper.rpc(peer_node_name, Actors, :register, [
               request
             ])

    # actor registered and present in the other node
    assert {:ok, [%{node: ^peer_node_name}]} =
             Spawn.NodeHelper.rpc(peer_node_name, ActorRegistry, :get_hosts_by_actor, [actor_id])

    # also present in self node

    assert {:ok, [%{node: ^peer_node_name}]} =
             loop_until_ok(fn -> ActorRegistry.get_hosts_by_actor(actor_id) end)

    assert {:ok, %RegistrationResponse{}} = Actors.register(request)

    # does not change host when registering a already registered actor
    assert {:ok, [%{node: ^peer_node_name}]} =
             Spawn.NodeHelper.rpc(peer_node_name, ActorRegistry, :get_hosts_by_actor, [actor_id])

    assert {:ok, [%{node: ^peer_node_name}]} =
             loop_until_ok(fn -> ActorRegistry.get_hosts_by_actor(actor_id) end)

    Spawn.NodeHelper.rpc(peer_node_name, Spawn.Cluster.StateHandoff.Manager, :clean, [
      peer_node_name
    ])

    assert loop_until_ok(fn ->
             ActorRegistry.get_hosts_by_actor(actor_id)
             |> case do
               {:not_found, []} -> {:ok, :not_found}
               _ -> {:error, :found}
             end
           end) == {:ok, :not_found}

    assert Spawn.NodeHelper.rpc(peer_node_name, ActorRegistry, :get_hosts_by_actor, [actor_id]) ==
             {:not_found, []}
  end
end
