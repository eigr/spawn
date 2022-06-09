# Spawn

**Actor Mesh Framework**

## Overview

Spawn is based on the sidecar proxy pattern to provide a multi-language Actor Model framework.
Spawn's technology stack on top of BEAM VM (Erlang's virtual machine) provides support for different languages from its native Actor model.

Spawn is made up of the following components:

* A semantic protocol based on Protocol Buffers
* A Sidecar Proxy written in Elixir that implements this protocol and persistent storage adapters.
* Support libraries in different programming languages.

## The Actor Model

According to [Wikipedia](https://en.wikipedia.org/wiki/Wikip%C3%A9dia:P%C3%A1gina_principal) Actor Model is:

"A mathematical model of concurrent computation that treats actor as the universal primitive of concurrent computation. In response to a message it receives, an actor can: [make local decisions, create more actors, send more messages, and determine how to respond to the next message received](https://www.youtube.com/watch?v=7erJ1DV_Tlo&t=22s). Actors may modify their own private state, but can only affect each other indirectly through messaging (removing the need for lock-based synchronization).

The actor model originated in [1973](https://www.ijcai.org/Proceedings/73/Papers/027B.pdf). It has been used both as a framework for a theoretical understanding of computation and as the theoretical basis for several practical implementations of concurrent systems."

The Actor Model was proposed by Carl Hewitt, Peter Bishop, and Richard Steiger and is inspired, according to him, by several characteristics of the physical world.
Although it emerged in the 70s of the last century, only in the last two decades of our century has this model gained strength in the software engineering communities due to the massive amount of existing data and the performance and distribution requirements of the most current applications. 

For more information about the Actor Model, see the following links:

https://en.wikipedia.org/wiki/Actor_model

https://codesync.global/media/almost-actors-comparing-pony-language-to-beam-languages-erlang-elixir/

https://www.infoworld.com/article/2077999/understanding-actor-concurrency--part-1--actors-in-erlang.html

https://doc.akka.io/docs/akka/current/general/actors.html


## The Sidecar Pattern

The sidecar pattern is a pattern for the implementation of Service Meshs and Microservices architectures where an external software is placed close to the real service in order to provide for it non-functional characteristics such as interfacing with the underlying network, routing, data transformation between other orthogonal requirements to the business.

The sidecar allows components to access services from any location or using any programming language. As a communication proxy mechanism, the sidecar can also act as a translator for cross-language dependency management. This is beneficial for distributed applications with complex integration requirements, and also for application systems that rely on external business integrations.

For more information about the Sidecar Pattern, see the following links:

https://www.techtarget.com/searchapparchitecture/tip/The-role-of-sidecars-in-microservices-architecture

https://docs.microsoft.com/en-us/azure/architecture/patterns/sidecar

https://www.youtube.com/watch?v=j7JKkbAiWuI

https://medium.com/nerd-for-tech/microservice-design-pattern-sidecar-sidekick-pattern-dbcea9bed783

## Spawn Architecture

Spawn takes the distribution, fault tolerance, and high concurrent capability of the Actor Model in its most famous implementation, which is the BEM Erlang VM implementation, and adds to that the flexibility and dynamism that the sidecar pattern offers to the build cross-platform and multi-language microservice-oriented architectures.

To achieve these goals, the Spawn architecture is composed of the following components:

***TODO insert diagram here.***

## The Protocol

Spawn is based on [Protocol Buffers](https://developers.google.com/protocol-buffers) and [gRPC](https://grpc.io/) to allow a heterogeneous layer of communication between different services that can, in turn, be implemented in any language that supports the gRPC protocol.

The Spawn protocol itself is described [here](https://github.com/eigr-labs/spawn/tree/main/apps/protos/priv/protos/eigr/functions/protocol/actors).

## SDKs

Another very important part of Spawn is the support languages implemented in different languages that aim to abstract all the specifics of the protocol and expose an easy and intuitive API to developers.

***TODO insert a SDKs list here***

## Development

Run:

```shell
PROXY_DATABASE_TYPE=mysql SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= iex --name spawn_a2@127.0.0.1 -S mix
```