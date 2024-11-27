# Features

- [x] Distribution. Automatic and transparent cluster formation via Kubernetes Operator.
  - [x] Erlang Distributed as transport.
    - [x] mTLS Support with Erlang Dist.
    - [x] Automatic renewal of certificates.
  - [x] Cross ActorSystem invocation with Nats distribution.
- [x] Configuration management via Kubernetes [CRDs](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/) and Envinronment Variables.
- [x] State Management. 
  - [x] Supported database adapters for persistent storage using:
    - [x] MariaDB
    - [x] Native (Distributed Mnesia with disk persistence)
    - [x] Postgres
  - [x] Write behind during execution and Write ahead during deactivation.
  - [x] Point in time Recovery. See Statestore for more information.
- [x] Automatic activation and deactivation of Actors.
- [x] Horizontal Scalability
  - [x] automatically controlled by the Operator using Kubernetes HPA based on memory and cpu.
  - [ ] automatically controlled by the Operator via Internal Metrics.
  - [ ] automatically controlled by the Operator via Custom Metrics.
- [x] Workflows
  - [x] Broadcast. Communicates with other actors through pubsub channel semantics.
    - [x] In Memory broadcast. Using [Phoenix.PubSub](https://github.com/phoenixframework/phoenix_pubsub) as transport.
    - [x] Nats broadcast. Using [Nats](https://nats.io/) as transport.
  - [x] External Broadcast. Sends events with pubsub semantics outside the actor system using the same transport types as Broadcast.
  - [x] Forwards. Forwards the input parameter of an action of an actor as input to another action of another actor.
  - [x] Pipes. Forwards the output type of an action of one actor to the input of an action of another actor. Like Unix pipes.
  - [x] Side effects. Sends an effect as a result of your computation for other Actors to handle.
  - [ ] Saga.
- [x] SDKs
  - [x] Elixir.
  - [x] Java.
  - [x] Java Springboot.
  - [x] Javascript browser lib. Under development.
  - [x] NodeJS + Typescript.
  - [x] Python.
  - [ ] Dart. Under development.
  - [ ] Go. Under development.
  - [ ] Rust. Under development.
  - [ ] .Net/C#. Under development.
- [x] Activators
  - [x] CronJob Scheduler.
  - [x] gRPC/HTTP.
    - [x] Unary.
    - [x] Bid Streamed.
    - [x] Stream In.
    - [ ] Stream Out.
    - [x] HTTP Transcoding.
  - [x] RabbitMQ.
  - [ ] Kafka.
  - [ ] Amazon SQS.
  - [ ] Google PubSub.
- [x] Observability
  - [x] OTLP Tracing.
  - [x] Prometheus Metrics.
- [x] Secucrity
  - [x] Database encryption with AES-ACM-V1.
  - [ ] Actor ACL (Access Control List). Under development.
  - [ ] Actor invocation with Authentication/Authorization Basic Auth flow. Under development.
  - [ ] Actor invocation with Authentication/Authorization JWT Auth flow. Under development.

[Back to Index](index.md)

[Next: Install](install.md)

[Previous: Architecture](architecture.md)