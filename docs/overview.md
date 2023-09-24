# Overview

**_What is Spawn?_**

There are two ways to answer this question, the short form would be something like:

> "Spawn is an Actor Model framework and Serverless Platform, which does a lot, really lot, of cool stuff that allows you to quickly deliver software oriented to your business domain."

Well since this answer doesn't say much, let's go the long way.

Spawn's main goal is to remove the complexity in developing services or microservices, providing simple and intuitive APIs, as well as a declarative deployment and configuration model and based on a Serverless architecture and Actor Model.
This leaves the developer to focus on developing the business domain while the platform deals with the complexities and infrastructure needed to support the scalable, resilient, distributed, and event-driven architecture that modern systems requires.

Spawn is based on the sidecar proxy pattern to provide a polyglot Actor Model framework and platform.
Spawn's technology stack, built on the [BEAM VM](https://www.erlang.org/blog/a-brief-beam-primer/) (Erlang's virtual machine) and [OTP](https://www.erlang.org/doc/design_principles/des_princ.html), provides support for different languages from its native Actor model.

Spawn is made up of the following components:

- A semantic protocol based on Protocol Buffers
- A Sidecar Proxy, written in Elixir, that implements this protocol and persistent storage
  adapters.
- Support libraries in different programming languages.

These are the main concepts:

1. **A Stateful Serverless Platform** running on top of Kubernetes, based on the Sidecar pattern and built on top of the BEAM VM.

2. **Inversion of State**. This means that unlike conventional Serverless architectures where the developer fetches state from persistent storage we on the other hand send the state as the context of the event the function is receiving. Bringing state closer to computing.

3. **Polyglot**. The platform must embrace as many software communities as possible. That's why the polyglot language model is adopted with SDK development for various programming languages.

4. **Less Infrastructure**. This means that our platform will give the developer the tools to focus only on their business without worrying about issues such as:

   - Resource allocation
   - Definition of connections and Pools
   - Service discovery
   - Source/Sink of Events
   - Other infrastructure issues

5. **The basic primitive is the Actor** (from the actors model) and **_not_** the Function (from the traditional serverless architectures).

6. Horizontal scalability with automatic **Activation** and **Deactivation** of Actors on demand.

Watch the video explaining how it works:

[![asciicast](https://asciinema.org/a/V2zUGsRmOjs0kI7swVTsKg7BQ.svg)](https://asciinema.org/a/V2zUGsRmOjs0kI7swVTsKg7BQ)

> **_NOTE:_** This video was recorded with an old version of the SDK for Java. That's why errors are seen in Deployment

### What problem Spawn solves

The advancement of Cloud Computing, Edge computing, Containers, Orchestrators, Data-
Oriented Services, and global-scale products aimed at serving audiences in various regions of
our world make the development of software today a task of enormous complexity. It is not
uncommon to see dozens, if not hundreds, of non-functional requirements that must be met
to build a system. All this complexity falls on the developer, who often does not have all the
knowledge or time to create such systems satisfactorily.

When studying this scenario, we realize that many of these current problems belong to the following groups:

- Fast business oriented software delivery.
- State management.
- Scalability.
- Resilience and fault tolerance.
- Distributed and/or regionally distributed computing.
- Integration Services.
- Polyglot services.

The actor model on which Spawn is based can solve almost all the problems on this list, with
Scalability, resilience, fault tolerance, and state management by far the top success stories of
different known actor model implementations. So what we needed to do was add Integration

Services, fast, business-oriented delivery, distributed computing, and polyglot services to the
recipe so we could revolutionize software development as we know it today.

That's precisely what we did with our platform called Eigr Functions Spawn.

Spawn takes care of the entire infrastructure layer by abstracting all the complex issues that
are not part of the business domain it is intended to address.

Particularly domains such as game development, machine learning pipelines, complex event
processing, real-time data ingestion, service integrations, financial or transactional services,
and logistics are some of the domains that can be mastered by the Eigr Functions Spawn
platform.

[Next: Features](features.md)

[Previous: Index](index.md)