# Projections

## Introduction

Projections are a powerful feature in Spawn that allow users to create actors of type projection. 
These actors enable you to create specialized views of state derived from one or more ***sourceable*** actors. This is especially useful for querying and aggregating data efficiently.

This document explains how to:

* Define ***sourceable*** actors.
* Create projection actors using Protobuf definitions.
* Implement and use projection actors in your application.

## Concepts

### Sourceable Actors

A **sourceable** actor is an actor whose state serves as the data source for projection actors. To make an actor sourceable, set the attribute `sourceable: true` when defining the actor.

### Projection Actors

A projection actor is a specialized actor that creates views or queries based on the state of one or more sourceable actors. These actors use Protobuf definitions to specify:

* Source actors (subjects attribute).
* Query options for views.
* Retention and ordering strategies.

## Defining Sourceable Actors

Sourceable actors are regular actors with the additional `sourceable: true` attribute. Below is an example using the Elixir SDK:

1. Define the actor’s Protobuf schema:

```protobuf
syntax = "proto3";

package inventory;

import "spawn/actors/extensions.proto";

message WarehouseState {
  string warehouse_id = 1 [(spawn.actors.actor_id) = true]; // Unique Warehouse ID
  repeated ProductInventory products = 2; // List of products in the warehouse (in a real case you probably wouldn't do this)
}

message ProductInventory {
  string product_id = 1 [(spawn.actors.actor_id) = true]; // Unique Product ID
  string name = 2;                                        // Product name
  int32 quantity = 3;                                     // Quantity in stock
}
```

2. Implement the sourceable actor:

```elixir
defmodule MyAppxample.Actors.WarehouseActor do
  use SpawnSdk.Actor,
    name: "WarehouseActor",
    state_type: Inventory.WarehouseState,
    # here we are indicating that the state of this actor 
    # can be captured by any projection actor that is interested
    sourceable: true 

  alias Inventory.{WarehouseState, ProductInventory}

  action("UpdateInventory", fn %Context{state: state} = ctx, %ProductInventory{} = product ->
    new_state =
      case state do
        nil -> %WarehouseState{warehouse_id: ctx.metadata.id, products: [product]}
        %WarehouseState{products: products} ->
          updated_products =
            Enum.map(products, fn p ->
              if p.product_id == product.product_id, do: %{p | quantity: product.quantity}, else: p
            end)

          %WarehouseState{state | products: updated_products}
      end

    Value.of()
    |> Value.state(new_state)
    |> Value.noreply!()
  end)
end
```

## Creating Projection Actors

Projection actors also are defined using **Protobuf**. A typical Protobuf file for a projection actor includes attributes to specify:

* `kind`: Defines the actor as a projection.
* `subjects`: Lists ***sourceable actors*** and their respective ***actions***.
* `spawn.actors.view`: Specifies query configuration for creating views.

### Defining Projection

1. Define input, output, and state types:

```protobuf
syntax = "proto3";

package inventory;

import "spawn/actors/extensions.proto";

message ConsolidatedInventory {
  string product_id = 1 [(spawn.actors.actor_id) = true]; // Unique Product ID
  string name = 2 [(spawn.actors.searchable) = true];     // Product name
  int32 total_quantity = 3; // Total quantity consolidated across all warehouses
}

message ProductQuery {
  string product_id = 1; // Product ID to be queried
}

message GeneralInventoryResponse {
  repeated ConsolidatedInventory inventory = 1;
}
```

2. Define the actor’s properties and actions:

```protobuf
syntax = "proto3";

package inventory;

// omit import for brevity...

service InventoryProjection {
  option (spawn.actors.actor) = {
    kind: PROJECTION
    stateful: true
    state_type: ".inventory.ConsolidatedInventory"
    subjects: [
      { actor: "WarehouseActor", source_action: "UpdateInventory", action: "Consolidate" }
    ]
  };

  rpc QueryProduct(.inventory.ProductQuery) returns (.inventory.GeneralInventoryResponse) {
    option (spawn.actors.view) = {
      query: "SELECT product_id, name, SUM(quantity) as total_quantity FROM projection_actor WHERE product_id = :product_id GROUP BY product_id, name"
      map_to: "inventory"
    };
  }

  rpc QueryAllProducts(.google.protobuf.Empty) returns (.inventory.GeneralInventoryResponse) {
    option (spawn.actors.view) = {
      query: "SELECT product_id, name, SUM(quantity) as total_quantity FROM projection_actor GROUP BY product_id, name"
      map_to: "inventory"
    };
  }
}
```

### Key Attributes:

* `subjects`: Specifies the sourceable actor and the action used to generate data for the projection. 
              It also specifies which projection actor action will be responsible for handling this request.

* `spawn.actors.view`: Defines the SQL-like query for creating views.

* `map_to: "inventory"`: Specifies the target field in response (`.inventory.GeneralInventoryResponse`) where query results will be mapped.

## Implementing Projection Actors

After defining the Protobuf, implement the projection actor using the Spawn SDK. For example:

```elixir
defmodule MyAppxample.Actors.InventoryProjectionActor do
  use SpawnSdk.Actor, name: "InventoryProjectionActor"

  alias Inventory.{ConsolidatedInventory, ProductInventory}

  action("Consolidate", fn %Context{} = ctx, %ProductInventory{} = product ->
    Value.of()
    |> Value.state(%ConsolidatedInventory{
      product_id: product.product_id, # This will effectively upsert the permanent storage by updating the quantity of each product by its product_id
      name: product.name,
      total_quantity: product.quantity
    })
  end)
end
```

## Invoking Projection Actor's Views

Projection actors support custom queries defined in the Protobuf. Examples include:

* `QueryProduct`: Retrieve consolidated stock for a specific product.
* `QueryAllProducts`: Retrieve the consolidated stock for all products.

### Query Example in Elixir

Once deployed, a projection actor can be invoked like any other actor. Use the query attributes defined in the Protobuf to fetch desired data like in Elixir SDK:

```elixir
alias Inventory.{InventoryProjection, ProductQuery, GeneralInventoryResponse}

{:ok, %GeneralInventoryResponse{inventory: inventories} = _response} = InventoryProjection.query_product(%ProductQuery{product_id: "some_id"}, metadata: %{"page" => 
"1", "page_size" => "50"})
```