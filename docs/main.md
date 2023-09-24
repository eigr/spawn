# Main Concepts

The sections below will discuss the main concepts that guided our architectural choices.

### The Protocol

Spawn is based on [Protocol Buffers](https://developers.google.com/protocol-buffers) and a
super simple [HTTP stack](https://github.com/eigr/spawn/blob/main/docs/protocol.md)
to allow a heterogeneous layer of communication between different services which can, in
turn, be implemented in any language that supports the gRPC protocol.

The Spawn protocol itself is described [here](https://github.com/eigr/spawn/blob/main/priv/protos/eigr/functions/protocol/actors/protocol.proto).

### The Actor Model

According to [Wikipedia](https://en.wikipedia.org/wiki/Wikip%C3%A9dia:P%C3%A1gina_principal) Actor Model is:

"A mathematical model of concurrent computation that treats actor as the universal primitive of concurrent computation. In response to a message it receives, an actor can: [make local decisions, create more actors, send more messages, and determine how to respond to the next message received](https://www.youtube.com/watch?v=7erJ1DV_Tlo&t=22s). Actors may modify their own private state, but can only affect each other indirectly through messaging (removing the need for lock-based synchronization).

The actor model originated in [1973](https://www.ijcai.org/Proceedings/73/Papers/027B.pdf). It has been used both as a framework for a theoretical understanding of computation and as the theoretical basis for several practical implementations of concurrent systems."

The Actor Model was proposed by Carl Hewitt, Peter Bishop, and Richard Steiger and is
inspired by several characteristics of the physical world.

Although it emerged in the 70s of the last century, only in the previous two decades of our
century has this model gained strength in the software engineering communities due to the
massive amount of existing data and the performance and distribution requirements of the
most current applications.

For more information about the Actor Model, see the following links:

https://en.wikipedia.org/wiki/Actor_model

https://codesync.global/media/almost-actors-comparing-pony-language-to-beam-languages-erlang-elixir/

https://www.infoworld.com/article/2077999/understanding-actor-concurrency--part-1--actors-in-erlang.html

https://doc.akka.io/docs/akka/current/general/actors.html

### The Sidecar Pattern

The sidecar pattern is a pattern for implementing Service Meshs and Microservices
architectures where an external software is placed close to the real service to provide non-
functional characteristics such as interfacing with the underlying network, routing, and data
transformation between other orthogonal requirements to the business.

The sidecar allows components to access services from any location or programming language.
The sidecar can also be a translator for cross-language dependency management as a
communication proxy mechanism. This benefits distributed applications with complex
integration requirements and applications that rely on external business integrations.

For more information about the Sidecar Pattern, see the following links:

https://www.techtarget.com/searchapparchitecture/tip/The-role-of-sidecars-in-microservices-architecture

https://docs.microsoft.com/en-us/azure/architecture/patterns/sidecar

https://www.youtube.com/watch?v=j7JKkbAiWuI

https://medium.com/nerd-for-tech/microservice-design-pattern-sidecar-sidekick-pattern-dbcea9bed783

### Nats

We use [Nats](https://nats.io/) for communication between different systems like Activators or cross ActorSystems. According to the project page "NATS is a simple, secure and performant communications system for digital systems, services and devices. NATS is part of the Cloud Native Computing Foundation (CNCF). NATS has over 40 client language implementations, and its server can run on-premise, in the cloud, at the edge, and even on a Raspberry Pi. NATS can secure and simplify design and operation of modern distributed systems."

Nats' ability to natively implement different topologies, as well as its minimalism, its cloud-native nature, and its capabilities to run on more constrained devices is what made us use Nats over other solutions. Nats allows Spawn to be able to provide strong isolation from an ActorSystem without limiting the user, allowing the user to still be able to communicate securely between different ActorSystems. Nats also facilitates the implementation of our triggers, called Activators, allowing those even without being part of an Erlang cluster to be able to invoke any actors.

[Previous: Local Development](local_development.md) 