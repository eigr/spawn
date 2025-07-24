# Elixir Workflows

Spawn has several mechanisms to facilitate integration between your actors or your application with the outside world. Below are some types of integration that Spawn provides:

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
    new_state = %MyState{value: new_value}

    Value.of()
    |> Value.state(new_state)
  end
end
```

> **_NOTE:_** Timers Actions are recorded as Actor metadata. Where in turn we use a synchronization mechanism via CRDTs to keep the metadata alive in the cluster while there is an active Spawn VM. That is, Timers Actions are ephemeral and therefore only exist while there is at least one active VM in the cluster.

In the example above the ´clock´ action will be called every 15 seconds.


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
    |> Value.response(%MyBusinessMessage{value: 999})
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
    |> Value.response(%MyBusinessMessage{value: msg.value + 1})
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

Forwards and pipes do not have an upper thread limit other than the request timeout.

[Next: Projections](projections.md)

[Previous: Actor Invocation](actor_invocation.md)