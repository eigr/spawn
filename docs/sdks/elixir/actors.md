# Elixir Actors

Spawn defines the following types of Actors:

* **Named Actors**: Named actors are actors whose name is defined at compile time. They also behave slightly differently 
Then unnamed actors and pooled actors. Named actors when they are defined with the stateful parameter equal to True are 
immediately instantiated when they are registered at the beginning of the program, they can also only be referenced by 
the name given to them in their definition.

* **Unnamed Actors**: Unlike named actors, unnamed actors are only created when they are named at runtime, that is, 
during program execution. Otherwise, they behave like named actors.

* **Pooled Actors**: Pooled Actors, as the name suggests, are a collection of actors that are grouped under the same name 
assigned to them at compile time. Pooled actors are generally used when higher performance is needed and are also 
recommended for handling serverless loads.

## Stateless Actors

```elixir
defmodule SpawnSdkExample.Actors.StatelessActor do
  use SpawnSdk.Actor,
    kind: :unnamed,
    stateful: false, # This is what defines this actor as stateless.
    state_type: Io.Eigr.Spawn.Example.MyState

end
```

## Stateful Actors

Below are examples for stateful actors for both Named and Unnamed types.

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

We declare two actions that the Actor can do. An initialization action that will be called every time an Actor instance is created and an action that will be responsible for performing a simple sum.

Note Keep in mind that any Action that has the names present in the list below will behave as an initialization Action and will be called when the Actor is started (if there is more than one Action with one of these names, only one will be called).

Defaults inicialization Action names: "**init**", "**Init**", "**setup**", "**Setup**"

### Stateful Unnamed Actors

We can also create Unnamed Dynamic/Lazy actors, that is, despite having its unnamed behavior defined at compile time, a Lazy actor will only have a concrete instance when it is associated with an identifier/name at runtime. Below follows the same previous actor being defined as Unnamed.

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

Notice that the only thing that has changed is the the kind of actor, in this case the kind is set to :unnamed.

> **_NOTE:_** Can Elixir programmers think in terms of Named vs Unnamed actors as more or less known at startup vs dynamically supervised/registered? That is, defining your actors directly in the supervision tree or using a Dynamic Supervisor for that.


## Considerations about Spawn actors

Another important feature of Spawn Actors is that the lifecycle of each Actor is managed by the platform itself. 
This means that an Actor will exist when it is invoked and that it will be deactivated after an idle time in its execution. 
This pattern is known as [Virtual Actors](#virtual-actors) but Spawn's implementation differs from some other known 
frameworks like [Orleans](https://www.microsoft.com/en-us/research/project/orleans-virtual-actors/) or 
[Dapr](https://docs.dapr.io/developing-applications/building-blocks/actors/actors-overview/) 
by defining a specific behavior depending on the type of Actor (named, unnamed, pooled, and etc...).

For example, named actors are instantiated the first time as soon as the host application registers them with the Spawn proxy. 
Whereas unnamed and pooled actors are instantiated the first time only when they receive their first invocation call.

[Next: Actor Invocation](actor_invocation.md)

[Previous: Getting Started](getting_started.md)