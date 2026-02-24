# Actor Types

Spawn supports different types of actors to fit various use cases. This guide covers all available actor types and when to use each.

## Named Actors

Named actors are known at compile time and are registered with a specific name in the system.

### Basic Named Actor

```elixir
defmodule SpawnSdkExample.Actors.NamedActor do
  use SpawnSdk.Actor,
    name: "jose", # Default is Full Qualified Module name
    kind: :named, # Default is already :named
    stateful: true, # Default is already true
    state_type: Io.Eigr.Spawn.Example.MyState,
    deactivate_timeout: 30_000,
    snapshot_timeout: 2_000

  require Logger

  alias Io.Eigr.Spawn.Example.{MyState, MyBusinessMessage}

  init fn %Context{state: state} = ctx ->
    Logger.info("[jose] Received InitRequest. Context: #{inspect(ctx)}")

    Value.of()
    |> Value.state(state)
  end

  action "Sum", fn %Context{state: state} = ctx, %MyBusinessMessage{value: value} = data ->
    Logger.info("Received Request: #{inspect(data)}. Context: #{inspect(ctx)}")

    new_value = if is_nil(state), do: value, else: (state.value || 0) + value

    Value.of(%MyBusinessMessage{value: new_value}, %MyState{value: new_value})
  end
end
```

**When to use Named Actors:**
- When you have a fixed number of actors that are known at design time
- Singleton actors that represent unique entities in your domain
- Actors that should be immediately available when the system starts

## Unnamed Actors

Unnamed actors are defined at compile time but only instantiated dynamically at runtime when associated with an identifier.

### Basic Unnamed Actor

```elixir
defmodule SpawnSdkExample.Actors.UnnamedActor do
  use SpawnSdk.Actor,
    name: "unnamed_actor",
    kind: :unnamed,
    state_type: Io.Eigr.Spawn.Example.MyState

  require Logger

  alias Io.Eigr.Spawn.Example.{MyState, MyBusinessMessage}

  action "Sum", fn %Context{state: state} = ctx, %MyBusinessMessage{value: value} = data ->
    Logger.info("Received Request: #{inspect(data)}. Context: #{inspect(ctx)}")

    new_value = if is_nil(state), do: value, else: (state.value || 0) + value

    Value.of(%MyBusinessMessage{value: new_value}, %MyState{value: new_value})
  end
end
```

### Using Unnamed Actors

```elixir
# Spawn an instance with a specific name
iex> SpawnSdk.spawn_actor("user_123", system: "spawn-system", actor: "unnamed_actor")
:ok

# Now you can invoke it
iex> SpawnSdk.invoke("user_123", system: "spawn-system", action: "sum", payload: %Io.Eigr.Spawn.Example.MyBusinessMessage{value: 1})
{:ok, %Io.Eigr.Spawn.Example.MyBusinessMessage{value: 1}}

# Or invoke without spawning (lazy spawning)
iex> SpawnSdk.invoke("user_456", ref: "unnamed_actor", system: "spawn-system", action: "sum", payload: %Io.Eigr.Spawn.Example.MyBusinessMessage{value: 1})
{:ok, %Io.Eigr.Spawn.Example.MyBusinessMessage{value: 1}}
```

**When to use Unnamed Actors:**
- When you need to create actors dynamically based on user data
- For modeling entities that have many instances (users, sessions, devices, etc.)
- When you don't know how many actors you'll need at compile time

## Pooled Actors

Pooled actors are unnamed actors that can be invoked without specifying a particular instance. The system automatically load-balances requests across multiple instances.

### Basic Pooled Actor

```elixir
defmodule SpawnSdkExample.Actors.PooledActor do
  use SpawnSdk.Actor,
    name: "pooled_actor",
    kind: :unnamed,
    stateful: false # Usually stateless for load balancing

  require Logger

  alias Io.Eigr.Spawn.Example.MyBusinessMessage

  action "Process", fn _ctx, %MyBusinessMessage{value: value} = data ->
    Logger.info("Processing request: #{inspect(data)} in #{inspect(self())}")

    # Simulate some processing
    :timer.sleep(100)
    
    Value.of(%MyBusinessMessage{value: value * 2})
  end
end
```

### Using Pooled Actors

```elixir
# Invoke with pooled: true - system handles load balancing
iex> SpawnSdk.invoke("pooled_actor", system: "spawn-system", action: "process", payload: %Io.Eigr.Spawn.Example.MyBusinessMessage{value: 5}, pooled: true)
{:ok, %Io.Eigr.Spawn.Example.MyBusinessMessage{value: 10}}
```

**When to use Pooled Actors:**
- For stateless operations that can be distributed across multiple instances
- When you need horizontal scaling for CPU-intensive tasks
- For processing queues or handling high-throughput operations

## Timer Actors

Actors can declare actions that execute periodically as timers.

### Timer Actor Example

```elixir
defmodule SpawnSdkExample.Actors.ClockActor do
  use SpawnSdk.Actor,
    name: "clock_actor",
    state_type: Io.Eigr.Spawn.Example.MyState,
    deactivate_timeout: 86_400_000

  require Logger

  alias Io.Eigr.Spawn.Example.MyState

  action "Clock", [timer: 15_000], fn %Context{state: state} = ctx ->
    Logger.info("[clock] Clock Actor Received Request. Context: #{inspect(ctx)}")

    new_value = if is_nil(state), do: 0, else: state.value + 1
    new_state = MyState.new(value: new_value)

    Value.of()
    |> Value.state(new_state)
  end
end
```

**When to use Timer Actors:**
- For periodic cleanup tasks
- Heartbeat or health check operations
- Scheduled data processing
- Periodic state synchronization

> **Note:** Timer actions are ephemeral and only exist while there is at least one active VM in the cluster.

## Task Actors (Stateless)

Task actors are designed for stateless operations and don't maintain state between invocations.

### Task Actor Example

```elixir
defmodule SpawnSdkExample.Actors.TaskActor do
  use SpawnSdk.Actor,
    name: "task_actor",
    stateful: false # No state management

  require Logger

  alias Io.Eigr.Spawn.Example.MyBusinessMessage

  action "Calculate", fn _ctx, %MyBusinessMessage{value: value} = data ->
    Logger.info("Calculating: #{inspect(data)}")

    # Perform stateless calculation
    result = value * value + 10

    Value.of(%MyBusinessMessage{value: result})
  end
end
```

**When to use Task Actors:**
- For pure functions or stateless operations
- Mathematical calculations
- Data transformations
- API integrations that don't require state

## Choosing the Right Actor Type

| Use Case | Actor Type | Stateful | Example |
|----------|------------|----------|---------|
| User sessions | Unnamed | Yes | Individual user data |
| System configuration | Named | Yes | Global settings |
| Message processing | Pooled | No | Queue processing |
| Scheduled jobs | Timer | Yes/No | Cleanup tasks |
| Calculations | Task | No | Math operations |

## Next Steps

- Learn about [actor configuration](actor_configuration.md)
- Explore the [client API](client_api.md)
- Check out [advanced features](../advanced/) for more complex patterns