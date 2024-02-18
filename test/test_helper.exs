Application.ensure_all_started(:mimic)

Mimic.copy(Actors.Node.Client)

Spawn.InitializerHelper.setup()

ExUnit.start()
Faker.start()

Spawn.InitializerHelper.spawn_peer("spawn_actors_node")

IO.puts("Nodes connected: #{inspect(Node.list())}")
