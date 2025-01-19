# Elixir Getting Started

Spawn Elixir SDK is the support library for the Spawn Actors System. Spawn is a Stateful Serverless Platform for providing the multi-language Actor Model. For a broader understanding of Spawn, please consult its official repository.

The advantage of the Elixir SDK over other SDKs is in Elixir's native ability to connect directly to an Erlang network. For this reason, the Elixir SDK allows any valid Elixir application to be part of a Spawn network without needing a sidecar attached.

## Installation

[Available in Hex](https://hex.pm/packages/spawn_sdk), the package can be installed
by adding `spawn_sdk` and `spawn_statestores_*` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:spawn_sdk, "~> 2.0.0-RC9"},

    # You can uncomment one of those dependencies if you are going to use Persistent Actors
    #{:spawn_statestores_mariadb, "~> 2.0.0-RC9"},
    #{:spawn_statestores_postgres, "~> 2.0.0-RC9"},
  ]
end
```

## How to use

After creating an Elixir application project, create the protobuf files for your business domain.
It is common practice to do this under the **priv/** folder. Let's demonstrate an example:

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

Now that we have defined our input and output types as Protobuf types we will need to compile these files to generate their respective Elixir modules. An example of how to do this can be found [here](https://github.com/eigr/spawn/blob/main/spawn_sdk/spawn_sdk_example/compile-example-pb.sh)

> **_NOTE:_** You need to have installed the elixir plugin for protoc. More information on how to obtain and install the necessary tools can be found here [here](https://github.com/elixir-protobuf/protobuf#usage)

Now that the protobuf types have been created we can proceed with the code. Example definition of an Actor.

In this example we are creating an actor in a Named way, that is, it is a known actor at compile time.

```elixir
defmodule SpawnSdkExample.Actors.MyActor do
  use SpawnSdk.Actor,
    name: "jose", # Default is Full Qualified Module name a.k.a __MODULE__
    kind: :named, # Default is already :named. Valid are :named | :unnamed
    stateful: true, # Default is already true
    state_type: Io.Eigr.Spawn.Example.MyState, # or :json if you don't care about protobuf types
    deactivate_timeout: 30_000,
    snapshot_timeout: 2_000

  require Logger

  alias Io.Eigr.Spawn.Example.{MyState, MyBusinessMessage}

  # The callback could also be referenced to an existing function:
  # action "SomeAction", &some_defp_handler/0
  # action "SomeAction", &SomeModule.handler/1
  # action "SomeAction", &SomeModule.handler/2

  init fn %Context{state: state} = ctx ->
    Logger.info("[joe] Received InitRequest. Context: #{inspect(ctx)}")

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

[Next: Actors](actors.md)

[Previous: SDKs](../../sdks.md)