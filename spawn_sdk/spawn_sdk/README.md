# Spawn Elixir SDK

<!-- MDOC !-->

Spawn Elixir SDK is the support library for the Spawn Actors System.
Spawn is a Stateful Serverless Platform for providing the multi-language Actor Model. For a broader understanding of Spawn, please consult its official [repository](https://github.com/eigr/spawn).

The advantage of the Elixir SDK over other SDKs is in Elixir's native ability to connect directly to an Erlang network. For this reason, the Elixir SDK allows any valid Elixir application to be part of a Spawn network without needing a sidecar attached.

## Quick Start

Get up and running with Spawn actors in minutes:

1. **Add to your dependencies:**

```elixir
def deps do
  [
    {:spawn_sdk, "~> 2.0.0-RC9"},
    # Optional: for persistent actors
    #{:spawn_statestores_postgres, "~> 2.0.0-RC9"},
  ]
end
```

2. **Create your first actor:**

```elixir
defmodule MyApp.Actors.Counter do
  use SpawnSdk.Actor,
    name: "counter",
    stateful: true,
    state_type: MyApp.Domain.CounterState

  action "increment", fn %Context{state: state}, %{value: value} ->
    new_count = (state.count || 0) + value
    new_state = %CounterState{count: new_count}
    
    Value.of(%{count: new_count}, new_state)
  end
end
```

3. **Set up your supervision tree:**

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      {SpawnSdk.System.Supervisor,
       system: "my-app", actors: [MyApp.Actors.Counter]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
```

4. **Use your actor:**

```elixir
SpawnSdk.invoke("counter", 
  system: "my-app", 
  action: "increment", 
  payload: %{value: 5}
)
#=> {:ok, %{count: 5}}
```

## Documentation

### 📚 Basic Concepts

- **[Quickstart Guide](guides/basic/quickstart.md)** - Get started with your first actor
- **[Actor Types](guides/basic/actor_types.md)** - Named, unnamed, pooled, and timer actors
- **[Actor Configuration](guides/basic/actor_configuration.md)** - Complete configuration reference
- **[Client API](guides/basic/client_api.md)** - Invoking actors and handling responses
- **[Supervision](guides/basic/supervision.md)** - Setting up your actor system

### 🚀 Advanced Features

- **[Side Effects](guides/advanced/side_effects.md)** - Asynchronous actor-to-actor communication
- **[Forwards and Pipes](guides/advanced/forwards_and_pipes.md)** - Request routing and processing pipelines
- **[Broadcast](guides/advanced/broadcast.md)** - Event-driven architectures and pub-sub patterns

## Key Features

- **🎭 Multiple Actor Types** - Named, unnamed, pooled, and timer actors
- **💾 State Management** - Persistent, transactional state with snapshots
- **🔄 Side Effects** - Asynchronous, fire-and-forget operations
- **📡 Broadcasting** - Pub-sub messaging between actors
- **🔀 Flow Control** - Forward and pipe patterns for request routing
- **⚡ High Performance** - Native Elixir clustering and distribution
- **🔧 Easy Integration** - Direct Phoenix and LiveView integration

## Examples

### Named Actor (Always Available)
```elixir
defmodule MyApp.Actors.ConfigService do
  use SpawnSdk.Actor,
    name: "config_service",
    kind: :named,
    stateful: true

  action "get_config", fn %Context{state: state}, %{key: key} ->
    value = Map.get(state.config, key)
    Value.of(%{key: key, value: value}, state)
  end
end
```

### Unnamed Actor (Dynamic Instances)
```elixir
defmodule MyApp.Actors.UserSession do
  use SpawnSdk.Actor,
    name: "user_session",
    kind: :unnamed,
    state_type: MyApp.Domain.SessionState

  action "login", fn %Context{}, %{user_id: user_id} ->
    session_state = %SessionState{
      user_id: user_id,
      logged_in_at: DateTime.utc_now()
    }
    
    Value.of(%{success: true}, session_state)
  end
end

# Usage
SpawnSdk.invoke("user_123", ref: "user_session", ...)
```

### Side Effects (Async Operations)
```elixir
action "process_order", fn ctx, order_data ->
  Value.of(order_result, new_state)
  |> Value.effects([
    SideEffect.of()
    |> SideEffect.effect("email_service", :send_confirmation, order_data)
    |> SideEffect.effect("inventory_service", :update_stock, order_data)
  ])
end
```

### Broadcasting (Event-Driven)
```elixir
action "create_user", fn ctx, user_data ->
  user_created_event = %UserCreated{...}
  
  Value.of(new_user, updated_state)
  |> Value.broadcast(Broadcast.to("user.events", user_created_event))
end
```

## Production Ready

Spawn is production-ready and battle-tested:

- **Kubernetes Native** - Full Kubernetes operator support
- **Observability** - OpenTelemetry integration, metrics, and tracing  
- **Persistence** - PostgreSQL and MySQL state stores
- **Scalability** - Horizontal scaling across multiple nodes
- **Security** - State encryption and secure networking

## Getting Help

- **[GitHub Issues](https://github.com/eigr/spawn/issues)** - Bug reports and feature requests
- **[Documentation](https://hexdocs.pm/spawn_sdk)** - Complete API documentation  
- **[Examples](https://github.com/eigr/spawn/tree/main/examples)** - Sample applications
- **[Community](https://github.com/eigr/spawn/discussions)** - Questions and discussions

## What's Next?

1. Follow the **[Quickstart Guide](guides/basic/quickstart.md)** to build your first actor
2. Explore **[Actor Types](guides/basic/actor_types.md)** to understand different patterns
3. Learn about **[Advanced Features](guides/advanced/)** for complex scenarios
4. Check out **[Examples](https://github.com/eigr/spawn/tree/main/examples)** for real-world patterns

---

**Ready to build distributed, stateful applications with ease? Start with the [Quickstart Guide](guides/basic/quickstart.md)!**

## Side Effects

Actors can also emit side effects to other Actors as part of their response. See an example:

```elixir
defmodule SpawnSdkExample.Actors.UnnamedActor do
  use SpawnSdk.Actor,
    kind: :unnamed,
    stateful: false,
    state_type: Io.Eigr.Spawn.Example.MyState

  require Logger

  alias Io.Eigr.Spawn.Example.{MyState, MyBusinessMessage}

  alias SpawnSdk.Flow.SideEffect

  action "Sum", fn %MyBusinessMessage{value: value} = data, %Context{state: state} = ctx ->
    Logger.info("Received Request: #{inspect(data)}. Context: #{inspect(ctx)}")

    new_value = if is_nil(state), do: value, else: (state.value || 0) + value

    result = %MyBusinessMessage{value: new_value}
    new_state = %MyState{value: new_value}

    Value.of()
    |> Value.response(result)
    |> Value.state(new_state)
    |> Value.effects(
      # This returns a list of side effects. In this case containing only one effect. However, multiple effects can be chained together,
      # just by calling the effect function as shown here.
      # The delay means that it will be fired asynchronously after 5000 milliseconds (5 seconds)
      # If only one effect is desired, you can also choose to use the to/3 function together with Value.effect().
      # Example: Values.effect(SideEffect.to(name, func, payload))
      SideEffect.of()
      |> SideEffect.effect("joe", :sum, result, delay: 5_000, scheduled_to: ~U[2020-01-01 10:00:00.145Z])
      # use delay or scheduled_to, not both
    )
  end
end

```

In the example above we see that the Actor joe will receive a request as a side effect from the Actor who issued this effect.

Side effects do not interfere with an actor's request-response flow. They will "always" be processed asynchronously and any response sent back from the Actor receiving the effect will be ignored by the effector.

## Pipe and Forward

Actors can also route some actions to other actors as part of their response. See an example:

```elixir
defmodule SpawnSdkExample.Actors.ForwardPipeActor do
  use SpawnSdk.Actor,
    name: "pipeforward",
    kind: :named,
    stateful: false

  require Logger

  alias Io.Eigr.Spawn.Example.MyBusinessMessage

  action "ForwardExampleAction", fn _ctx, %MyBusinessMessage{} = msg ->
    Logger.info("Received request with #{msg.value}")

    Value.of()
    |> Value.forward(
      Forward.to("second_actor", "sum_plus_one")
    )
    |> Value.void()
  end

  action "PipeExampleAction", fn _ctx, %MyBusinessMessage{} = msg ->
    Logger.info("Received request with #{msg.value}")

    Value.of()
    |> Value.response(MyBusinessMessage.new(value: 999))
    |> Value.pipe(
      Pipe.to("second_actor", "sum_plus_one")
    )
    |> Value.void()
  end
end

defmodule SpawnSdkExample.Actors.SecondActorExample do
  use SpawnSdk.Actor,
    name: "second_actor",
    stateful: false

  require Logger

  alias Io.Eigr.Spawn.Example.MyBusinessMessage

  action "SumPlusOne", fn _ctx, %MyBusinessMessage{} = msg ->
    Logger.info("Received request with #{msg.value}")

    Value.of()
    |> Value.response(MyBusinessMessage.new(value: msg.value + 1))
    |> Value.void()
  end
end

```

We are returning void in both examples so we dont care about what is being stored in the actor state.

In the case above, every time you call the `forward_example` the second_actor's `sum_plus_one` function will receive the value forwarded originally in the invocation as its input. The end result will be:

```elixir
iex> SpawnSdk.invoke("pipeforward", system: "spawn-system", action: "forward_example", payload: %Io.Eigr.Spawn.Example.MyBusinessMessage{value: 1})
{:ok, %Io.Eigr.Spawn.Example.MyBusinessMessage{value: 2}}
```

For the Pipe example, the the second_actor's `sum_plus_one` function will always receive `%MyBusinessMessage{value: 999}` due to getting the value from the previous specification in the `pipe_example` action, the end result will be:

```elixir
iex> SpawnSdk.invoke("pipeforward", system: "spawn-system", action: "pipe_example", payload: %Io.Eigr.Spawn.Example.MyBusinessMessage{value: 1})
{:ok, %Io.Eigr.Spawn.Example.MyBusinessMessage{value: 1000}}
```

## Broadcast

Actors can also send messages to a group of actors at once as an action callback. See the example below:

```elixir
defmodule Fleet.Actors.Driver do
  use SpawnSdk.Actor,
    kind: :unnamed,
    state_type: Fleet.Domain.Driver

  alias Fleet.Domain.{
    Driver,
    OfferRequest,
    OfferResponse,
    Point
  }

  require Logger

  @brain_actor_channel "fleet.controllers.topic"

  action "UpdatePosition", fn %Context{state: %Driver{id: name} = driver} = ctx, %Point{} = position ->
    Logger.info(
      "Received Update Position Event. Position: [{inspect(position)}]. Context: #{inspect(ctx)}"
    )

    driver_state = %Driver{driver | position: position}

    %Value{}
    |> Value.of(driver_state, driver_state)
    |> Value.broadcast(
      Broadcast.to(
        @brain_actor_channel,
        driver_state
      )
    )
  end
end

defmodule Fleet.Actors.FleetControllersActor do
  use SpawnSdk.Actor,
    kind: :unnamed,
    channels: [
      {"fleet.controllers.topic", "update_position_receive"}
    ] # or just ["fleet.controllers.topic"] and it will forward to a action called receive

  alias Fleet.Domain.Point

  action "UpdatePositionReceive", fn _ctx, %Point{} = position ->
    Logger.info(
      "Driver [#{name}] Received Update Position Event. Position: [#{inspect(position)}]"
    )

    Value.of()
  end
end
```

In the case above, every time an Actor "driver" executes the update_position action it will send a message to all the actors participating in the channel called "fleet-controllers".

### Broadcast to External Subscribers

Sometimes you may want to send events out of ActorSystem using Phoenix.PubSub.
One way to do this is to take advantage of the same Broadcast infrastructure that Spawn offers you but indicating an external channel. Below is an example:

1. Create a Listener to receive the events using the `SpawnSdk.Channel.Subscriber` helper module.

```elixir
defmodule SpawnSdkExample.Subscriber do
  @moduledoc """
  This module exemplifies how to listen for pubsub events that were emitted by actors but that will be treated not by actors but as normal pubsub events.
  This is particularly useful for integrations between Spawn and Phoenix LiveView.
  """
  use GenServer
  require logger

  alias SpawnSdk.Channel.Subscriber

  @impl true
  define init(state) do
    Subscriber.subscribe("external.channel")
    {:ok, state}
  end

  @impl true
  def handle_info({:receive, payload}, state) do
    Logger.info("Received pubsub event #{inspect(payload)}")
    {:noreply, state}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end
end
```

You need to match using the {:receive, payload} tuple in your handle_info.

> **_NOTE:_** By default SpawnSdk.Channel.Subscriber will subscribe to pubsub using the atom :actor_channel as an argument.

    If you need to change this, just configure your configuration as follows:

**_config.exs_**

```elixir
config :spawn,
   pubsub_group: :your_channel_group_here
```

2. SpawnSdk.System.Supervisor.

```elixir
defmodule SpawnSdkExample.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {
        SpawnSdk.System.Supervisor,
        system: "spawn-system",
        actors: [
          SpawnSdkExample.Actors.JoeActor
        ],
        extenal_subscribers: [
          {SpawnSdkExample.Subscriber, []}
        ]
      }
    ]

    opts = [strategy: :one_for_one, name: SpawnSdkExample.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

The important thing here is to use the external_subscribers attribute. As seen above :external_subscribers accepts a list of specs as a parameter.

3. Set your actor as you normally would and emit your broadcast events using Broadcast.to(channel, payload).

```elixir
defmodule SpawnSdkExample.Actors.JoeActor do
  use SpawnSdk.Actor,
    name: "joe",
    state_type: Io.Eigr.Spawn.Example.MyState

  require Logger
  alias Io.Eigr.Spawn.Example.{MyState, MyBusinessMessage}

  action "Sum", fn %Context{state: state} = ctx, %MyBusinessMessage{value: value} = data ->
    Logger.info("[joe] Received Request: #{inspect(data)}. Context: #{inspect(ctx)}")

    new_value =
      if is_nil(state) do
        0 + value
      else
        (state.value || 0) + value
      end

    response = %MyBusinessMessage{value: new_value}

    %Value{}
    |> Value.of(response, %MyState{value: new_value})
    |> Value.broadcast(Broadcast.to("my.channel", response))
  end
end
```

## Timers

Actors can also declare Actions that act recursively as timers. See an example below:

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

> **_NOTE:_** Timers Actions are recorded as Actor metadata. Where in turn we use a synchronization mechanism via CRDTs to keep the metadata alive in the cluster while there is an active Spawn VM. That is, Timers Actions are ephemeral and therefore only exist while there is at least one active VM in the cluster.

In the example above the ´clock´ action will be called every 15 seconds.

## Declaring the supervision tree

Once we define our actors we can now declare our supervision tree:

```elixir
defmodule SpawnSdkExample.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {
        SpawnSdk.System.Supervisor,
        system: "spawn-system",
        actors: [
          SpawnSdkExample.Actors.MyActor,
          SpawnSdkExample.Actors.UnnamedActor,
          SpawnSdkExample.Actors.ClockActor,
          SpawnSdkExample.Actors.PooledActor
        ]
      }
    ]

    opts = [strategy: :one_for_one, name: SpawnSdkExample.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

## Default Actions

Actors also have some standard actions that are not implemented by the user and that can be used as a way to get the state of an actor without the invocation requiring an extra trip to the host functions. You can think of them as a cache of their state, every time you invoke a default action on an actor it will return the value directly from the Sidecar process without this target process needing to invoke its equivalent host function.

Let's take an example. Suppose Actor Joe wants to know the current state of Actor Robert. What Joe can do is invoke Actor Robert's default action called get_state. This will make Actor Joe's sidecar find Actor Robert's sidecar somewhere in the cluster and Actor Robert's sidecar will return its own state directly to Joe without having to resort to your host function, this in turn will save you a called over the network and therefore this type of invocation is faster than invocations of user-defined actions usually are.

Any invocations to actions with the following names will follow this rule: "**get**",
"**Get**",
"**get_state**",
"**getState**",
"**GetState**"

> **_NOTE:_** You can override this behavior by defining your actor as an action with the same name as the default actions. In this case it will be the Action defined by you that will be called, implying perhaps another network roundtrip

## Running

To deploy your actors in a cluster you need to use our Controller for Kubernetes. Detailed information on how to proceed can be found [here](https://github.com/eigr/spawn#install) and [here](https://github.com/eigr/spawn#getting-started).
But you can also run your Elixir application in the traditional way as follows:

```
MIX_ENV=prod USER_FUNCTION_PORT=8092 PROXY_DATABASE_TYPE=mysql SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= iex --name spawn_a2@127.0.0.1 -S mix
```

> **_NOTE:_** For reasons of compatibility with our controller, it is necessary to configure your Spawn application using environment variables instead of the traditional Elixir configuration mechanism.

> **_WARNING:_** This example uses the MySQL database as persistent storage for its actors. And it is also expected that you have previously created a database called eigr-functions-db in the MySQL instance.

The full example of this application can be found [here](https://github.com/eigr/spawn/tree/main/spawn_sdk/spawn_sdk_example).

And links to other examples can be found in our github [readme page](https://github.com/eigr/spawn#examples).

## Client API Examples

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
iex> SpawnSdk.invoke("robert_lazy", ref: "unnamed_actor", system: "spawn-system", action: "sum", payload: %Io.Eigr.Spawn.Example.MyBusinessMessage{value: 1})
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
