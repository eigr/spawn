# Spawn Actor Types

Spawn supports various types of actors, each tailored to specific use cases in distributed systems. These types allow developers to design flexible, scalable, and maintainable architectures. Below are the actor types and their features.

---

***__Note__***: In these subsequent sections we will give examples using the SDK for the Elixir programming language. However, all features are available in each of the supported languages; see the SDKs chapter for more information in your preferred language.

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

### **Example of Named Actor Implementation**

```elixir
defmodule MyAppExample.Actors.Inventory do
  use SpawnSdk.Actor, name: "InventoryActor"

  alias Inventory.{InventoryState, UpdateInventoryRequest, InventoryResponse}

  action("UpdateInventory", fn %Context{} = ctx, %UpdateInventoryRequest{} = request ->
    Value.of()
    |> Value.state(%InventoryState{
      product_id: request.product_id,
      quantity: ctx.state.quantity + request.quantity
    })
    |> Value.response(%InventoryResponse{message: "Inventory updated successfully"})
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

### **Example of Unnamed Actor Implementation**

```elixir
defmodule MyAppExample.Actors.SessionActor do
  use SpawnSdk.Actor, name: "SessionActor"

  action("StartSession", fn %Context{} = ctx, %StartSessionRequest{} = request ->
    Value.of()
    |> Value.state(%SessionState{
      session_id: request.session_id,
      user_data: request.user_data
    })
    |> Value.response(%SessionResponse{message: "Session started"})
  end)
end
```

**__NOTE__**: Although the actor above was initially associated with a name (in this case SessionActor), this in turn serves only as a reference so that a child instance of this actor can later be created at runtime, where this instance will receive the "real" name. See [each SDK's documentation](sdks.md) to learn more about creating unnamed actors.

## **3. Task Actors**

### **Description**

- **Definition**: Actors designed for executing specific tasks and can be deployed on specialized nodes in the cluster.
- **Usage**: Useful for stateless or stateful tasks like computations, machine learning inference, or data transformations.
- **Use Cases**: 
  - High-compute tasks.
  - Stateless operations requiring horizontal scalability.
  - Machine Learning workloads running in a gpu.

### **Protobuf Definition**

```proto
syntax = "proto3";

package example;

message Genome {
  repeated float genes = 1;
}

message BestGenome {
  repeated float genes = 1; // A list of genes representing the genome
  float fitness = 2;       // The fitness score of the genome
}

message FitnessResult {
  float fitness = 1;
}

service GeneticTaskActor {
  // Evaluates a genome and updates the actor's state if it has better fitness
  rpc EvaluateGenome(Genome) returns (FitnessResult);

  // Retrieves the best genome and its fitness score
  rpc GetBestGenome(google.protobuf.Empty) returns (BestGenome);
}
```

### **Example of Task Actor Implementation**

```elixir
defmodule MyAppExample.Actors.GeneticTaskActor do
  use SpawnSdk.Actor,
    name: "GeneticTaskActor",
    state_type: Example.BestGenome,
    kind: :task

  alias Example.{Genome, FitnessResult, BestGenome}
  alias Nx.Tensor

  action("EvaluateGenome", fn %Context{state: %BestGenome{fitness: best_fitness} = current_state} = _ctx, %Genome{genes: genes} ->
    fitness = evaluate_genome(genes)

    if fitness > best_fitness do
      updated_state = %BestGenome{genes: genes, fitness: fitness}
      Value.of()
      |> Value.state(updated_state)
      |> Value.response(fitness_result(fitness))
    else
      Value.of()
      |> Value.state(current_state)
      |> Value.response(fitness_result(fitness))
    end
  end)

  defp evaluate_genome(genes) do
    genes
    |> Nx.tensor()
    |> Nx.pow(2)
    |> Nx.sum()
    |> Nx.negate()
    |> Nx.to_number()
  end

  defp fitness_result(fitness) do
    %FitnessResult{fitness: fitness}
  end
end
```

***__Notice__***: In the previous examples we defined the actor properties using the protobuf `spawn.actors.actor` option, but in this example we did it directly in the SDK code during the Actor implementation. Both ways are allowed and the same parameters are available in each of these options. However, we strongly recommend using the protobuf option instead of the options in the actor code.

When using Task actors, we can specify special rules during the deployment phase so that the cluster scheduler provisions this actor on specific type of machines. See the example of a deployment definition for a Task actor that needs a machine that uses a GPU:

```yaml
---
apiVersion: spawn-eigr.io/v1
kind: ActorHost
metadata:
  name: topology-example
  namespace: default
  annotations:
    spawn-eigr.io/actor-system: spawn-system
spec:
  topology:
    nodeSelector:
      gpu: "false"
    tolerations:
      - key: "cpu-machines"
        operator: "Exists"
        effect: "NoExecute"
  host:
    image: eigr/task-actors-examples:x.x.x 
    taskActors:
      - actorName: Compute
        workerPool:
          min: 0
          max: 10
          maxConcurrency: 100
          bootTimeout: 30000
          callTimeout: 30000
          oneOff: "false"
          idleShutdownAfter: 30000
        topology:
          nodeSelector:
            gpu: "true"
          tolerations:
            - key: "gpu-machines"
              operator: "Exists"
              effect: "NoExecute"
```

In the example above, we are informing that all actors except the task actor called Compute will execute on nodes in Kubernetes whose nodeSelector is set to nodeSelector.gpu: false. And for the task actor called Compute, it was defined that it will only execute on machines that have GPUs available.

***__Note__***: It is not Spawn's responsibility to provision nodes in Kubernetes, this is done by Kubernetes' own [Scheduler component](https://kubernetes.io/docs/concepts/scheduling-eviction/kube-scheduler/). What we did here was to [tell Kubernetes where](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/) it should provision a [pod](https://kubernetes.io/docs/concepts/workloads/pods/) for our application. Spawn will create a new pod when there is a request for a task actor and Kubernetes will do the rest of the work for us. Together with tools for [Cluster autoscaling](https://kubernetes.io/docs/concepts/cluster-administration/cluster-autoscaling/) this allows for interesting topologies and possible cost reduction since it is not necessary to permanently allocate nodes to run a task actor action.

## **4. Projection Actors**

### **Description**

- **Definition**: Actors that create materialized views from sourceable actor state.
- **Usage**: Provide read-optimized projections for efficient querying and reporting.
- **Use Cases**: 
  - Aggregating state across multiple actors.
  - Generating queryable views for reporting.

### **Protobuf Definition**

```protobuf
syntax = "proto3";

package inventory;

import "spawn/actors/extensions.proto";

message ProductInventoryState {
  string product_id = 1 [(spawn.actors.actor_id) = true];

  string name = 2 [(spawn.actors.searchable) = true];

  string warehouse_id = 3 [(spawn.actors.searchable) = true];

  int32 quantity = 4;
}

message ProductQuery {
  string product_id = 1;
}

message WarehouseQuery {
  string warehouse_id = 1;
}

message GeneralInventoryResponse {
  repeated ProductInventory inventory = 1; // Consolidated list of products
}

service InventoryProjectionActor {
  option (spawn.actors.actor) = {
    kind: PROJECTION
    stateful: true
    state_type: ".inventory.ProductInventory"
    subjects: [
      { actor: "WarehouseProductActor", source_action: "UpdateProduct", action: "Consolidate" }
    ]
  };

  rpc QueryProduct(.inventory.ProductQuery) returns (.inventory.GeneralInventoryResponse) {
    option (spawn.actors.view) = {
      query: "SELECT product_id, name, warehouse_id, SUM(quantity) FROM projection_actor WHERE product_id = :product_id GROUP BY product_id, name, warehouse_id"
      map_to: "inventory"
    };
  }

  rpc QueryWarehouse(.inventory.WarehouseQuery) returns (.inventory.GeneralInventoryResponse) {
    option (spawn.actors.view) = {
      query: "SELECT product_id, name, warehouse_id, quantity FROM projection_actor WHERE warehouse_id = :warehouse_id"
      map_to: "inventory"
    };
  }

  rpc QueryAllProducts(.google.protobuf.Empty) returns (.inventory.GeneralInventoryResponse) {
    option (spawn.actors.view) = {
      query: "SELECT product_id, name, warehouse_id, quantity FROM projection_actor"
      map_to: "inventory",
      page_size: "100"
    };
  }
}
```

### **Example of Projection Actor Implementation**

```elixir
defmodule MyAppxample.Actors.InventoryProjectionActor do
  use SpawnSdk.Actor, name: "InventoryProjectionActor"

  alias Inventory.WarehouseState # state of sourceable actor
  alias Inventory.ProductInventoryState # state of this projections

  action("Consolidate", fn %Context{} = ctx, %WarehouseState{} = product ->
    Value.of()
    |> Value.state(%ProductInventoryState{
      product_id: product.product_id,
      name: update.name,
      warehouse_id: update.warehouse_id,
      quantity: update.quantity
    })
    |> Value.noreply!()
  end)
end
```

[See the specific chapter on projections](projections.md) to better understand how this type of actor works.

## **5. Pooled Actors**

### **Description**

- **Definition**: Stateless actors deployed in a pool for high-concurrency workloads.
- **Usage**: Automatically load-balanced across the cluster, ensuring scalability.
- **Use Cases**: 
  - Handling large volumes of requests concurrently.
  - Stateless microservices.
  - Administrative tasks without persistence requirements.

### **Protobuf Definition**

```protobuf
syntax = "proto3";

package example;

message PooledRequest {
  string task_id = 1;
}

message PooledResponse {
  string message = 1;
}

service PooledActor {
  option (spawn.actors.actor) = {
    kind: POOLED,
    min_pool_size: 1,
    max_pool_size: 10
  };

  rpc HandleTask(.example.PooledRequest) returns (.example.PooledResponse) {
    option (google.api.http) = {
      post: "/pooled/task"
      body: "*"
    };
  }
}
```

### **Example of Pooled Actor Implementation**

```elixir
defmodule MyAppExample.Actors.PooledActor do
  use SpawnSdk.Actor, name: "PooledActor"

  alias Example.{PooledRequest, PooledResponse}

  action("HandleTask", fn _ctx, %PooledRequest{} = request ->
    Value.reply(%PooledResponse{message: "Task handled: #{request.task_id}"})
  end)
end
```

**__Attention__**: Pooled actors are being reimplemented and have therefore been temporarily removed from this ***2.x.x** release.


## Stateful and Stateless Actors


| Actor Type 	| Stateful 	| Stateless   |                                 Notes                                 	|
|:----------:	|:--------: |:---------:  |:---------------------------------------------------------------------:	|
| Named      	|     ✔️     |     ✔️     	| Can manage global shared state or act as stateless service endpoints.   |
| Unnamed    	|     ✔️     |     ✔️     	| Useful for session actors (stateful) or dynamic workers (stateless).    |
| Task       	|     ✔️     |     ✔️     	| Can persist task context or process tasks statelessly.                  |
| Pooled     	|    ❌     |     ✔️       | Always stateless, designed for high-concurrency workloads.            	|
| Projection 	|     ✔️     |    ❌       | Always stateful for materialized views                                	|

### Key Considerations

* **Stateful Actors**: Require proper state management and storage. They are useful when the actor's behavior depends on accumulated data over time.

* **Stateless Actors**: Simpler to implement and scale, as they do not require persistence mechanisms or consistent state handling.

By supporting both stateful and stateless behaviors, Spawn provides the flexibility needed to design distributed systems that efficiently balance complexity, scalability, and functionality.

[Back to Index](index.md)

[Next: Projections](projections.md)

[Previous: Architecture](architecture.md)