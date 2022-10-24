# Spawn Elixir SDK

Spawn Elixir SDK is the support library for the Spawn Actors System.

Spawn is based on the sidecar proxy pattern to provide the multi-language Actor Model framework.
Spawn's technology stack on top of BEAM VM (Erlang's virtual machine) provides support for different languages from its 
native Actor model.

For a broader understanding of Spawn please consult its official [repository](https://github.com/eigr-labs/spawn).

## Installation

[Available in Hex](https://hex.pm/packages/spawn_sdk), the package can be installed
by adding `spawn_sdk` and `spawn_statestores` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:spawn_sdk, "~> 0.1.0"},

    # You can remove this if you will ONLY USE non-persistent actors
    {:spawn_statestores, "~> 0.1.0"}
  ]
end
```

## How to use

After creating an elixir application project create the protobuf files for your business domain.
It is common practice to do this under the priv/ folder. Let's demonstrate an example:

```protobuf
syntax = "proto3";

package io.eigr.spawn.example;

message MyState {
  int32 value = 1;
}

message MyBusinessMessage {
  int32 value = 1;
}
```

It is important to try to separate the type of message that must be stored as the actors' state from the type of messages 
that will be exchanged between their actors' operations calls. In other words, the Actor's internal state is also represented 
as a protobuf type, and it is a good practice to separate these types of messages from the others in its business domain.

In the above case `MyState` is the type protobuf that represents the state of the Actor that we will create later 
while `MyBusiness` is the type of message that we will send and receive from this Actor.

Now that we have defined our input and output types as Protobuf types we will need to compile these files to generate their respective Elixir modules. An example of how to do this can be found [here](https://github.com/eigr/spawn/blob/main/apps/spawn_sdk_example/compile-example-pb.sh)

> **_NOTE:_** You need to have installed the elixir plugin for protoc. More information on how to obtain and install the necessary tools can be found here [here](https://github.com/elixir-protobuf/protobuf#usage) 

Now that the protobuf types have been created we can proceed with the code. Example definition of an Actor:

```elixir
defmodule SpawnSdkExample.Actors.MyActor do
  use SpawnSdk.Actor,
    name: "jose",
    persistent: true,
    state_type: Io.Eigr.Spawn.Example.MyState,
    deactivate_timeout: 30_000,
    snapshot_timeout: 2_000

  require Logger

  alias Io.Eigr.Spawn.Example.{MyState, MyBusinessMessage}

  defact sum(
           %MyBusinessMessage{value: value} = data,
           %Context{state: state} = ctx
         ) do
    Logger.info("Received Request: #{inspect(data)}. Context: #{inspect(ctx)}")

    new_value =
      if is_nil(state) do
        0 + value
      else
        (state.value || 0) + value
      end

    %Value{}
    |> Value.of(%MyBusinessMessage{value: new_value}, %MyState{value: new_value})
    |> Value.reply!()
  end
end

```

In this example we are creating an actor in an Named/Eager way ie it is a known actor at compile time. We can also create Unnamed Dyncamic/Lazy actors, that is, despite having its abstract behavior defined at compile time, a Lazy actor will only have a concrete instance when it is associated with an identifier/name at runtime. Below follows the same previous actor being defined as abstract.

```elixir
defmodule SpawnSdkExample.Actors.AbstractActor do
  use SpawnSdk.Actor,
    abstract: true,
    persistent: true,
    state_type: Io.Eigr.Spawn.Example.MyState

  require Logger

  alias Io.Eigr.Spawn.Example.{MyState, MyBusinessMessage}

  defact sum(
           %MyBusinessMessage{value: value} = data,
           %Context{state: state} = ctx
         ) do
    Logger.info("Received Request: #{inspect(data)}. Context: #{inspect(ctx)}")

    new_value =
      if is_nil(state) do
        0 + value
      else
        (state.value || 0) + value
      end

    %Value{}
    |> Value.of(%MyBusinessMessage{value: new_value}, %MyState{value: new_value})
    |> Value.reply!()
  end
end
```

Notice that the only thing that has changed is the absence of the name argument definition and the abstract argument definition being set to true.

> **_NOTE:_** Can Elixir programmers think in terms of named vs abstract actors as more or less known at startup vs dynamically supervised/registered? That is, defining your actors directly in the supervision tree or using a Dynamic Supervisor for that.

## Side Effects

Actors can also emit side effects to other Actors as part of their response. See an example:

```elixir
defmodule SpawnSdkExample.Actors.AbstractActor do
  use SpawnSdk.Actor,
    abstract: true,
    persistent: false,
    state_type: Io.Eigr.Spawn.Example.MyState

  require Logger

  alias Io.Eigr.Spawn.Example.{MyState, MyBusinessMessage}

  alias SpawnSdk.Flow.SideEffect

  defact sum(%MyBusinessMessage{value: value} = data, %Context{state: state} = ctx) do
    Logger.info("Received Request: #{inspect(data)}. Context: #{inspect(ctx)}")

    new_value =
      if is_nil(state) do
        0 + value
      else
        (state.value || 0) + value
      end

    result = %MyBusinessMessage{value: new_value}
    new_state = %MyState{value: new_value}

    Value.of()
    |> Value.value(result)
    |> Value.state(new_state)
    |> Value.effects(
      # This returns a list of side effects. In this case containing only one effect. However, multiple effects can be chained together,
      # just by calling the effect function as shown here.
      # If only one effect is desired, you can also choose to use the to/3 function together with Value.effect().
      # Example: Values.effect(SideEffect.to(name, func, payload))
      SideEffect.of()
      |> SideEffect.effect("joe", :sum, result)
    )
    |> Value.reply!()
  end
end

```

In the example above we see that the Actor joe will receive a request as a side effect from the Actor who issued this effect.

Side effects do not interfere with an actor's request-response flow. They will "always" be processed asynchronously and any response sent back from the Actor receiving the effect will be ignored by the effector.

## Broadcast

Actors can also send messages to a group of actors at once as an action callback. See the example below:

```elixir
defmodule Fleet.Actors.Driver do
  use SpawnSdk.Actor,
    abstract: true,
    # Set ´driver´ channel for all actors of the same type (Fleet.Actors.Driver)
    channel: "drivers",
    state_type: Fleet.Domain.Driver

  alias Fleet.Domain.{
    Driver,
    OfferRequest,
    OfferResponse,
    Point
  }

  require Logger

  @brain_actor_channel "fleet-controllers"

  defact update_position(%Point{} = position, %Context{state: %Driver{id: name} = driver} = ctx) do
    Logger.info(
      "Driver [#{name}] Received Update Position Event. Position: [#{inspect(position)}]. Context: #{inspect(ctx)}"
    )

    driver_state = %Driver{driver | position: position}

    %Value{}
    |> Value.of(driver_state, driver_state)
    |> Value.broadcast(
      Broadcast.to(
        @brain_actor_channel,
        "driver_position",
        driver_state
      )
    )
    |> Value.reply!()
  end
end
```

In the case above, every time an Actor "driver" executes the update_position action it will send a message to all the actors participating in the channel called "fleet-controllers".

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

  @set_timer 15_000
  defact clock(_ignored_data, %Context{state: state} = ctx) do
    Logger.info("Clock Actor Received Request. Context: #{inspect(ctx)}")

    new_state =
      if is_nil(state) do
        %MyState{value: 0}
      else
        state
      end

    Value.of()
    |> Value.state(new_state)
    |> Value.noreply!()
  end
end
```

> **_NOTE:_** Timers Actions are ephemeral and only exist while the Actor is Enabled, ie running. Therefore Timers are not persistent and will not reactivate a timer's Actor after it is deactivated. Note that in the example above we set the value of deactivate timeout to an exceptionally high number, this is done to make the Actor remain active.

In the example above the ´clock´ action will be called every 15 seconds.

### Declaring the supervision tree

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
          SpawnSdkExample.Actors.AbstractActor
        ]
      }
    ]

    opts = [strategy: :one_for_one, name: SpawnSdkExample.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

To run the application via iex we can use the following command:

```
MIX_ENV=prod USER_FUNCTION_PORT=8092 PROXY_DATABASE_TYPE=mysql SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= iex --name spawn_a2@127.0.0.1 -S mix
```

> **_NOTE:_** This example uses the MySQL database as persistent storage for its actors. And it is also expected that you have previously created a database called eigr-functions-db in the MySQL instance.

The full example of this application can be found [here](https://github.com/eigr/spawn/tree/main/apps/spawn_sdk_example).

### Test App

Invoke Actors:

```elixir
SpawnSdk.invoke(
  "joe", 
  system: "spawn-system",
  command: "sum",
  payload: %Io.Eigr.Spawn.Example.MyBusinessMessage{value: 1}
)
```

You can invoke actor default functions like "get" to get its current state

```elixir
SpawnSdk.invoke(
  "joe", 
  system: "spawn-system",
  command: "get"
)
```

Spawning Actors:

```elixir
SpawnSdk.spawn_actor("robert", system: "spawn-system", actor: SpawnSdkExample.Actors.AbstractActor)
```

Invoke Spawning Actors:

```elixir
SpawnSdk.invoke(
  "robert",
  system: "spawn-system",
  command: "sum",
  payload: %Io.Eigr.Spawn.Example.MyBusinessMessage{value: 1}
)
```

Invoke Actors in a lazy way without having to spawn before:

```elixir
SpawnSdk.invoke(
  "robert_lazy",
  ref: SpawnSdkExample.Actors.AbstractActor,
  system: "spawn-system",
  command: "sum",
  payload: %Io.Eigr.Spawn.Example.MyBusinessMessage{value: 1}
)
```

### Deploy

Ready you now have a valid Elixir application for use in a Spawn cluster. However, you will still need to generate a container image with your application so that you can use it together with the Spawn Operator for Kubernetes.

This and other information can be found in the [documentation]().
