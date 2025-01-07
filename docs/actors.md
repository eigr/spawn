# Spawn Actor Types

Spawn supports various types of actors, each tailored to specific use cases in distributed systems. These types allow developers to design flexible, scalable, and maintainable architectures. Below are the actor types and their features.

---

## **1. Named Actors**

### **Description**

- **Definition**: Singleton actors that exist as a single instance in the system. Their names are given at compile time.
- **Usage**: Named during compilation and provide globally accessible functionality.
- **Use Cases**: 
  - Managing shared resources.
  - Acting as entry points for business workflows.

### **Protobuf Definition**

```proto
syntax = "proto3";

package example;

import "spawn/actors/extensions.proto";
import "google/api/annotations.proto";

message InventoryState {
  string product_id = 1 [(spawn.actors.actor_id) = true];
  int32 quantity = 2;
}

message UpdateInventoryRequest {
  string product_id = 1;
  int32 quantity = 2;
}

message InventoryResponse {
  string message = 1;
}

service InventoryActor {
  option (spawn.actors.actor) = {
    kind: NAMED
    stateful: true
    state_type: ".example.InventoryState"
  };

  rpc UpdateInventory(.example.UpdateInventoryRequest) returns (.example.InventoryResponse) {
    option (google.api.http) = {
      post: "/inventory/update"
      body: "*"
    };
  }
}
``` 

### **Example of Actor Implementation**

```elixir
defmodule MyAppExample.Actors.Inventory do
  use SpawnSdk.Actor, name: "InventoryActor"

  alias Inventory.{InventoryState, UpdateInventoryRequest, InventoryResponse}

  action("UpdateInventory", fn %Context{} = ctx, %UpdateInventoryRequest{} = request ->
    Value.state(%InventoryState{
      product_id: request.product_id,
      quantity: ctx.state.quantity + request.quantity
    })
    |> Value.reply(%InventoryResponse{message: "Inventory updated successfully"})
  end)
end
```

## **2. Unnamed Actors**

### **Description**

- **Definition**: Actors dynamically created at runtime with unique names. Their names are given at runtime.
- **Usage**: Typically spawned by parent actors to handle session-specific, temporary tasks, or mapping business entities generated during the application lifecycle.
- **Use Cases**: 
  - Session management.
  - Transactions.
  - Dynamic workflows or user-specific processes.

### **Protobuf Definition**

```proto
syntax = "proto3";

package example;

import "spawn/actors/extensions.proto";
import "google/api/annotations.proto";

message SessionState {
  string session_id = 1;
  string user_data = 2;
}

message StartSessionRequest {
  string session_id = 1;
  string user_data = 2;
}

message SessionResponse {
  string message = 1;
}

service SessionActor {
  option (spawn.actors.actor) = {
    kind: UNNAMED
    stateful: true
    state_type: ".example.SessionState"
  };

  rpc StartSession(.example.StartSessionRequest) returns (.example.SessionResponse) {
    option (google.api.http) = {
      post: "/session/start"
      body: "*"
    };
  }
}
```

### **Example of Actor Implementation**

```elixir
defmodule MyAppExample.Actors.SessionActor do
  use SpawnSdk.Actor, nam: "SessionActor"

  action("StartSession", fn %Context{} = ctx, %StartSessionRequest{} = request ->
    Value.state(%SessionState{
      session_id: request.session_id,
      user_data: request.user_data
    })
    |> Value.reply(%SessionResponse{message: "Session started"})
  end)
end
```

**__NOTE__**: Although the actor above was initially associated with a name (SessionActor), this in turn serves only as a reference so that a child instance of this actor can later be created at runtime, where this instance will receive the real name. See each SDK's documentation to learn more about creating unnamed actors.
