# Actor Invocation

To invoke Actors, use:

```elixir
iex> SpawnSdk.invoke("joe", system: "spawn-system", action: "Sum", payload: %Io.Eigr.Spawn.Example.MyBusinessMessage{value: 1})
{:ok, %Io.Eigr.Spawn.Example.MyBusinessMessage{value: 12}}
```

You can invoke actor default functions like "get" to get its current state

```elixir
SpawnSdk.invoke("joe", system: "spawn-system", action: "get")
```

Spawning Actors:

```elixir
iex> SpawnSdk.spawn_actor("robert", system: "spawn-system", actor: "unnamed_actor")
:ok
```

You can also create Actors so that they are initialized from a certain revision number, that is, initialize actors from a specific point in time.

```elixir
iex> SpawnSdk.spawn_actor("robert", system: "spawn-system", actor: "unnamed_actor", revision: 2)
:ok
```

In the above case the actor will be initialized with its state restored from the state as it was in revision 2 of its previous lifetime.

Invoke Spawned Actors:

```elixir
iex> SpawnSdk.invoke("robert", system: "spawn-system", action: "sum", payload: %Io.Eigr.Spawn.Example.MyBusinessMessage{value: 1})
{:ok, %Io.Eigr.Spawn.Example.MyBusinessMessage{value: 16}}
```

Invoke Actors in a lazy way without having to spawn them before:

```elixir
iex> SpawnSdk.invoke("robert_lazy", ref: SpawnSdkExample.Actors.UnnamedActor, system: "spawn-system", action: "sum", payload: %Io.Eigr.Spawn.Example.MyBusinessMessage{value: 1})
{:ok, %Io.Eigr.Spawn.Example.MyBusinessMessage{value: 1}}
```

Invoke Actors with a delay set in milliseconds:

```elixir
iex> SpawnSdk.invoke("joe", system: "spawn-system", action: "ping", delay: 5_000)
{:ok, :async}
```

Invoke Actors scheduled to a specific DateTime:

```elixir
iex> SpawnSdk.invoke("joe", system: "spawn-system", action: "ping", scheduled_to: ~U[2023-01-01 00:32:00.145Z])
{:ok, :async}
```

Invoke Pooled Actors:

```elixir
iex> SpawnSdk.invoke("pooled_actor", system: "spawn-system", action: "ping", pooled: true)
{:ok, nil}
```


[Next: Workflows](workflows.md)

[Previous: Actors](actors.md)