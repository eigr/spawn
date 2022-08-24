# Spawn

**Actor Mesh Platform**

## Overview

Spawn is based on the sidecar proxy pattern to provide a multi-language Actor Model framework and platform.
Spawn's technology stack on top of BEAM VM (Erlang's virtual machine) provides support for different languages from its native Actor model.

Spawn is made up of the following components:

* A semantic protocol based on Protocol Buffers
* A Sidecar Proxy written in Elixir that implements this protocol and persistent storage adapters.
* Support libraries in different programming languages.

## What problem Spawn solves

With the advancement of Cloud Computing, Edge computing, Containers, Orchestrators, Data Oriented Services, and development of global scale products aimed at serving audiences in various regions of our world make the development of software today is a task of enormous complexity. It is not uncommon to see dozens, if not hundreds of non-functional requirements that need to be met to build a system. All this complexity falls on the developer, who often does not have all the knowledge or time to build such systems satisfactorily.
When studying this scenario, we realize that many of these current problems belong to the following groups:

- Fast delivery and business oriented.
- State management.
- Scalability.
- Resilience and fault tolerance.
- Distributed and/or regionally distributed computing.
- Integration Services.
- Polyglot services.

The actor model, which Spawn is based on, can solve almost all the problems on this list, with Scalability, resilience, fault tolerance, and state management by far the top success stories of different known actor model implementations. So what we needed to do was add Integration Services, fast, business-oriented delivery, distributed computing, and multilingual services to the recipe so we could revolutionize software development as we know it today. That's exactly what we did with our platform called Eigr Functions Spawn.
Spawn takes care of the entire infrastructure layer by abstracting all the complex issues that are not part of the business domain it is intended to address.
Particularly domains such as games, machine learning and AI, real-time data ingestion, integration between services, financial or transactional services, logistics are some of the domains that can be mastered by the Eigr Functions Spawn platform.

## Spawn Architecture

Spawn takes the distribution, fault tolerance, and high concurrent capability of the Actor Model in its most famous implementation, which is the BEAM Erlang VM implementation, and adds to that the flexibility and dynamism that the sidecar pattern offers to the build cross-platform and multi-language microservice-oriented architectures.

To achieve these goals, the Eigr Functions Spawn architecture is composed of the following components:

![image info](docs/diagrams/spawn-architecture.jpg)

As seen above, the Eigr Functions Spawn platform architecture is separated into different components, each with their own responsibility. We will detail the components below.

* **k8s Operator:** Responsible for interacting with the Kubernetes API and coordinating the deployments of the other components. The user interacts with it using our specific CRDs ([Custom Resource Definitions](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)). We'll talk more about our CRDs later.

* **Cloud Storage:** Despite not being directly part of the platform, it is worth mentioning here that Spawn uses user-defined persistent storage to store the state of its Actors. Different types of persistent storage can be used, such as relational databases such as MySQL, Postgres, among others. In the future, we will support other types of databases, both relational and non-relational.

* **Activators:** Activators are applications responsible for ingesting data from external sources for certain user-defined actors and are configured through their own CRD. They are basically responsible for listening to a user-configured event and forward this event through a direct invocation to a specific target actor. Different types of Activators exist to consume events from different providers such as Google PubSub, RabbitMQ, Amazon SQS and etc.

* **Actor Host Function:** The container where the user defines his actors and all the business logic of his actors around the state of these actors through a specific SDK for each supported programming language.

* **Spawn Sidecar Proxy:** The centerpiece of the gear is our sidecar proxy, in turn it is responsible for managing the entire lifecycle of user-defined actors through our SDKs and also responsible for managing the state of these actors in persistent storage. The Spawn proxy is also capable of allowing the user to develop different integration flows between its actors such as Forwards, Effects, Pipes, and in the future other important standards such as Saga, Aggregators, Scatter-Gather, external invocations, and others.
Our proxy connects directly and transparently to all cluster members without the need for a single point of failure, ie a true mesh network.

## Custom Resources

Spawn defines some custom Resources for the user to interact with the API for deploying Spawn artifacts in Kubernetes. We'll talk more about these CRDs in the Getting Started section but for now we'll list each of these resources below for a general understanding of the concepts:

* **ActorSystem CRD:** The ActorSystem CRD must be defined by the user before it attempts to deploy any other Spawn features. In it, the user defines some general parameters for the functioning of the actor cluster, as well as defines the parameters of the persistent storage connection for a given system. Multiple ActorSystems can be defined but remember that they must be referenced equally in the Actor Host Functions. Examples of this CRD can be found in the [examples/k8s folder](examples/k8s/system.yaml).

* **Node CRD:** A Node is a cluster member application. A Node by definition is a Kubernetes Deployment and will contain two containers, one containing the Actor Host Function user application and another container for the Spawn proxy which is responsible for connecting to the proxies cluster via Distributed Erlang and also for providing all the necessary abstractions for the functioning of the system such as state management, activation and passivation of actors, among other infrastructure tasks. Examples of this CRD can be found in the [examples/k8s folder](examples/k8s/node.yaml).

* **Activator CRD:** Activator CRD defines any means of inputting supported events such as queues, topics, http or grpc endpoints and maps these events to the appropriate actor that will handle them. Examples of this CRD can be found in the [examples/k8s folder](examples/k8s/activators/amqp.yaml).

## SDKs

Another very important part of Spawn is the SDKs implemented in different languages that aim to abstract all the specifics of the protocol and expose an easy and intuitive API to developers.

|  SDK 	                                                                | Language  |
|---	                                                                |---        |
|[C# SDK](https://github.com/eigr-labs/spawn-dotnet-sdk)                | C#	    |
|[Go SDK](https://github.com/eigr-labs/spawn-go-sdk)  	                | Go  	    |
|[Spring Boot SDK](https://github.com/eigr-labs/spawn-springboot-sdk)  	| Java	    |
|[NodeJS/Typescript SDK](https://github.com/eigr-labs/spawn-node-sdk)   | Node	    |
|[Python SDK](https://github.com/eigr-labs/spawn-python-sdk)  	        | Python    |
|[Rust SDK](https://github.com/eigr-labs/spawn-rust-sdk)  	            | Rust	    |


## Main Concepts

In the sections below we will talk about the main concepts that guided our architectural choices.

### The Actor Model

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


### The Sidecar Pattern

The sidecar pattern is a pattern for the implementation of Service Meshs and Microservices architectures where an external software is placed close to the real service in order to provide for it non-functional characteristics such as interfacing with the underlying network, routing, data transformation between other orthogonal requirements to the business.

The sidecar allows components to access services from any location or using any programming language. As a communication proxy mechanism, the sidecar can also act as a translator for cross-language dependency management. This is beneficial for distributed applications with complex integration requirements, and also for application systems that rely on external business integrations.

For more information about the Sidecar Pattern, see the following links:

https://www.techtarget.com/searchapparchitecture/tip/The-role-of-sidecars-in-microservices-architecture

https://docs.microsoft.com/en-us/azure/architecture/patterns/sidecar

https://www.youtube.com/watch?v=j7JKkbAiWuI

https://medium.com/nerd-for-tech/microservice-design-pattern-sidecar-sidekick-pattern-dbcea9bed783


### The Protocol

Spawn is based on [Protocol Buffers](https://developers.google.com/protocol-buffers) and a super simple [HTTP stack](https://github.com/eigr-labs/spawn/blob/main/docs/protocol.md) to allow a heterogeneous layer of communication between different services which can in turn be implemented in any language that supports the gRPC protocol.

The Spawn protocol itself is described [here](https://github.com/eigr-labs/spawn/blob/main/apps/protos/priv/protos/eigr/functions/protocol/actors/protocol.proto).


## Getting Started

TODO

## Project Development

Run:

```shell
PROXY_DATABASE_TYPE=mysql SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= iex --name spawn_a2@127.0.0.1 -S mix
```

Tests:

```shell
MIX_ENV=test PROXY_DATABASE_TYPE=mysql PROXY_HTTP_PORT=9001 SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= elixir --name spawn@127.0.0.1 -S mix test
```