# Spawn Elixir SDK

Spawn Elixir SDK is the support library for the Spawn Actors System.

Spawn is based on the sidecar proxy pattern to provide the multi-language Actor Model framework.
Spawn's technology stack on top of BEAM VM (Erlang's virtual machine) provides support for different languages from its 
native Actor model.

For a broader understanding of Spawn please consult its official [repository](https://github.com/eigr-labs/spawn).

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `spawn_sdk` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:spawn_sdk, "~> 0.1.0"}
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

  @impl true
  def handle_command(
        {:sum, %MyBusinessMessage{value: value} = data},
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

In this example we are creating an actor in an Eager way ie it is a known actor at compile time. We can also create Lazy actors, that is, despite having its abstract behavior defined at compile time, a Lazy actor will only have a concrete instance when it is associated with an identifier/name at runtime. Below follows the same previous actor being defined as abstract.

```elixir
defmodule SpawnSdkExample.Actors.AbstractActor do
  use SpawnSdk.Actor,
    abstract: true,
    persistent: true,
    state_type: Io.Eigr.Spawn.Example.MyState

  require Logger
  alias Io.Eigr.Spawn.Example.{MyState, MyBusinessMessage}

  @impl true
  def handle_command(
        {:sum, %MyBusinessMessage{value: value} = data},
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
SpawnSdk.System.SpawnSystem.invoke("spawn-system", "jose", "sum", %Io.Eigr.Spawn.Example.MyBusinessMessage{value: 1})
```

Spawning Actors:

```elixir
SpawnSdk.System.SpawnSystem.spawn_actor("spawn-system", "robert", SpawnSdkExample.Actors.AbstractActor)
```

Invoke Spawning Actors:

```elixir
SpawnSdk.System.SpawnSystem.invoke("spawn-system", "robert", "sum", %Io.Eigr.Spawn.Example.MyBusinessMessage{value: 1})
```

### Deploy

Ready you now have a valid Elixir application for use in a Spawn cluster. However, you will still need to generate a container image with your application so that you can use it together with the Spawn Operator for Kubernetes.

This and other information can be found in the [documentation]().