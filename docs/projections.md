# Projections

## Introduction

Projections are a powerful feature in Spawn that allow users to create actors of type projection. These actors enable you to create specialized views of state derived from one or more sourceable actors. This is especially useful for querying and aggregating data efficiently.

This document explains how to:

* Define sourceable actors.
* Create projection actors using Protobuf definitions.
* Implement and use projection actors in your application.

## Concepts

### Sourceable Actors

A sourceable actor is an actor whose state serves as the data source for projection actors. To make an actor sourceable, set the attribute `sourceable: true` when defining the actor.

### Projection Actors

A projection actor is a specialized actor that creates views or queries based on the state of one or more sourceable actors. These actors use Protobuf definitions to specify:

* Source actors (subjects attribute).
* Query options for views.
* Retention and ordering strategies.

## Defining Sourceable Actors

Sourceable actors are regular actors with the additional `sourceable: true` attribute. Below is an example using the Elixir SDK:

```elixir
defmodule SpawnSdkExample.Actors.ClockActor do
  use SpawnSdk.Actor,
    name: "ClockActor",
    state_type: Io.Eigr.Spawn.Example.MyState,
    deactivate_timeout: 15_000,
    sourceable: true # here we are indicating that the state of this actor can be captured by any projection actor that is interested

  alias Io.Eigr.Spawn.Example.MyState

  action("Clock", [timer: 5_000], fn %Context{state: state} = ctx ->
    # Some logic....
    new_state = MyState.new(value: new_value)

    Value.of()
    |> Value.state(new_state) # this state will be captured by a projection actor later
    |> Value.noreply!()
  end)
end
```

## Creating Projection Actors

Projection actors are defined using **Protobuf**. A typical Protobuf file for a projection actor includes attributes to specify:

* `kind`: Defines the actor as a projection (PROJECTION).
* `subjects`: Lists sourceable actors and their respective actions.
* `spawn.actors.view`: Specifies query configuration for creating views.

### Defining Projection 

```protobuf
syntax = "proto3";

import "google/api/annotations.proto";
import "example/example.proto";
import "spawn/actors/extensions.proto";

package example.actors;

service ProjectionActor {
  option (spawn.actors.actor) = {
    kind: PROJECTION
    stateful: true
    state_type: ".example.ExampleState"
    snapshot_interval: 60000
    deactivate_timeout: 999999999
    strict_events_ordering: false
    subjects: [
      { actor: "ClockActor", action: "Clock" } 
    ]
    events_retention_strategy: {
      duration_ms: 86000
    }
  };

  rpc ExampleView(.example.ValuePayload) returns (.example.SomeQueryResponse) {
    option (spawn.actors.view) = {
      query: "SELECT * FROM projection_actor WHERE id = :id"
      map_to: "results"
    };
  }

  rpc All(.example.ValuePayload) returns (.example.SomeQueryResponse) {
    option (spawn.actors.view) = {
      query: "SELECT * FROM projection_actor WHERE :enum_test IS NULL"
      map_to: "results"
      page_size: 40
    };
  }
}
```

### Key Attributes:

* `subjects`: Specifies the sourceable actor and the action used to generate data for the projection.

* `spawn.actors.view`: Defines the SQL-like query for creating views.

* `map_to`: Specifies the target field in response (`.example.SomeQueryResponse`) where query results will be mapped.

## Implementing Projection Actors

After defining the Protobuf, you can implement the projection actor using the Spawn SDK. Here’s an example in Elixir:

```elixir
defmodule SpawnSdkExample.Actors.ProjectionActor do
  use SpawnSdk.Actor, name: "ProjectionActor"

  require Logger

  alias Io.Eigr.Spawn.Example.MyState
  alias Example.ExampleState

  action("Transform", fn %Context{} = ctx, %MyState{} = payload ->
    Logger.info("[projection] Projection Actor Received Request. Context: #{inspect(ctx)}")

    Value.of()
    |> Value.state(%ExampleState{
      id: "id_#{payload.value}",
      value: payload.value,
      data: %Example.ExampleState.Data{
        id: "data_id_01",
        test: "data_test"
      }
    })
  end)
end
```

