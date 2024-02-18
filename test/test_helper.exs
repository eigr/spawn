Spawn.InitializerHelper.setup()

ExUnit.start()

Spawn.InitializerHelper.spawn_peer("spawn_actors_node")

IO.puts("Nodes connected: #{inspect(Node.list())}")
