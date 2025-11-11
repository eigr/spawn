# Quickstart Guide

This guide will help you get started with Spawn Elixir SDK quickly.

## Installation

Add `spawn_sdk` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:spawn_sdk, "~> 2.0.0-RC9"},

    # Optional: if you are going to use Persistent Actors
    #{:spawn_statestores_mariadb, "~> 2.0.0-RC9"},
    #{:spawn_statestores_postgres, "~> 2.0.0-RC9"},
  ]
end
```

## Quick Example

Let's create a simple counter actor to demonstrate the basics:

### 1. Define your Protobuf messages

Create a file `priv/example.proto`:

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

### 2. Compile Protobuf files

You need to compile these protobuf files to generate Elixir modules. 

> **Note:** You need the elixir protobuf plugin installed. See [protobuf documentation](https://github.com/elixir-protobuf/protobuf#usage) for installation instructions.

### 3. Create your first Actor

```elixir
defmodule MyApp.Actors.Counter do
  use SpawnSdk.Actor,
    name: "counter",
    stateful: true,
    state_type: Io.Eigr.Spawn.Example.MyState

  require Logger

  alias Io.Eigr.Spawn.Example.{MyState, MyBusinessMessage}

  # Initialization action - called when actor starts
  init fn %Context{state: state} = ctx ->
    Logger.info("Counter actor initialized. Context: #{inspect(ctx)}")

    Value.of()
    |> Value.state(state || %MyState{value: 0})
  end

  # Sum action - adds a value to the current state
  action "Sum", fn %Context{state: state} = ctx, %MyBusinessMessage{value: value} = data ->
    Logger.info("Received Sum request: #{inspect(data)}")

    current_value = if is_nil(state), do: 0, else: state.value
    new_value = current_value + value

    Value.of(%MyBusinessMessage{value: new_value}, %MyState{value: new_value})
  end
end
```

### 4. Set up your supervision tree

```elixir
defmodule MyApp.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {
        SpawnSdk.System.Supervisor,
        system: "spawn-system",
        actors: [
          MyApp.Actors.Counter
        ]
      }
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

### 5. Use your Actor

```elixir
# Add 5 to the counter
iex> SpawnSdk.invoke("counter", system: "spawn-system", action: "Sum", payload: %Io.Eigr.Spawn.Example.MyBusinessMessage{value: 5})
{:ok, %Io.Eigr.Spawn.Example.MyBusinessMessage{value: 5}}

# Add 3 more
iex> SpawnSdk.invoke("counter", system: "spawn-system", action: "Sum", payload: %Io.Eigr.Spawn.Example.MyBusinessMessage{value: 3})
{:ok, %Io.Eigr.Spawn.Example.MyBusinessMessage{value: 8}}

# Get current state
iex> SpawnSdk.invoke("counter", system: "spawn-system", action: "get")
{:ok, %Io.Eigr.Spawn.Example.MyState{value: 8}}
```

That's it! You now have a working Spawn actor that maintains state across invocations.

## Next Steps

- Learn about [different actor types](actor_types.md)
- Understand [actor configuration](actor_configuration.md)
- Explore [client API](client_api.md)
- Check out [advanced features](../advanced/) for side effects, forwards, and pipes