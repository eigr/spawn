Mimic.copy(Actors.Node.Client)

ExUnit.start()
Faker.start()

Spawn.InitializerHelper.setup()

Actors.Supervisors.ProtocolSupervisor.start_link(%{})
Actors.Supervisors.EntitySupervisor.start_link(%{})

node = Spawn.NodeHelper.spawn_peer("spawn_actors_node", applications: [:sidecar])

Spawn.NodeHelper.rpc(node, Spawn.InitializerHelper, :setup, [])
Spawn.NodeHelper.rpc(node, Actors.Supervisors.ProtocolSupervisor, :start_link, [%{}])
Spawn.NodeHelper.rpc(node, Actors.Supervisors.EntitySupervisor, :start_link, [%{}])

IO.puts("Nodes connected: #{inspect(Node.list())}")
