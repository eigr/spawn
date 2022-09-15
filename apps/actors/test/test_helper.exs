Mimic.copy(Actors.Node.Client)

ExUnit.start()
Faker.start()

Spawn.Cluster.Node.Registry.start_link(%{})
