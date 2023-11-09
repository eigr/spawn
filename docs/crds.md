# Custom Resources Definitions

Spawn defines some custom Resources for the user to interact with the API for deploying Spawn artifacts in Kubernetes. We'll talk more about these CRDs in the Getting Started section but for now we'll list each of these resources below for a general understanding of the concepts:

- **ActorSystem CRD:** The user must define the ActorSystem CRD before it attempts to
  deploy any other Spawn features. In it, the user defines some general parameters for the
  functioning of the actor cluster and the parameters of the persistent storage connection for a
  given system. Multiple ActorSystems can be defined but remember that they must be
  referenced equally in the Actor Host Functions. Examples of this CRD can be found in the
  [examples/k8s/simple folder](../examples/k8s/simple/system.yaml).

- **ActorHost CRD:** A ActorHost is a cluster member application. An ActorHost, by
  definition, is a Kubernetes Deployment and will contain two containers, one containing the
  Actor Host Function user application and another container for the Spawn proxy, which is
  responsible for connecting to the proxies cluster via Distributed Erlang and also for providing
  all the necessary abstractions for the functioning of the system such as state management,
  activation, and passivation of actors, among other infrastructure tasks. Examples of this CRD
  can be found in the [examples/k8s/simple folder](../examples/k8s/simple/host.yaml).

- **Activator CRD:** Activator CRD defines any means of inputting supported events such as
  queues, topics, HTTP, or grpc endpoints and maps these events to the appropriate actor to
  handle them. Examples of this CRD can be found in the [examples/k8s/activators
  folder](../examples/k8s/activators).

[Next: Actor System Resource](crds/actor_system.md)

[Previous: SDKs](sdks.md)