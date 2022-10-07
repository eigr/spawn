Mimic.copy(Actors.Node.Client)

ExUnit.start()
Faker.start()

node = Spawn.NodeHelper.spawn_peer("spawn_actors_node", applications: [:sidecar])

Spawn.NodeHelper.rpc(node, Spawn.InitializerHelper, :setup, [])

IO.puts("Nodes connected: #{inspect(Node.list())}")
