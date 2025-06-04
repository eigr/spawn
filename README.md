# Spawn: Drive Your Business with Stateful Computing

<!-- MDOC !-->

![Sepp](docs/images/sepp-elixir-254-400.png#gh-light-mode-only)
![Sepp](docs/images/sepp-elixir-254-400.png#gh-dark-mode-only)

**Actor Mesh Runtime**

![ci](https://github.com/eigr/spawn/actions/workflows/ci.yaml/badge.svg)
[![docs-ci](https://github.com/eigr/spawn/actions/workflows/pages/pages-build-deployment/badge.svg)](https://github.com/eigr/spawn/actions/workflows/pages/pages-build-deployment)
[![OpenSSF Best Practices](https://www.bestpractices.dev/projects/10543/badge)](https://www.bestpractices.dev/projects/10543)
![last commit](https://img.shields.io/github/last-commit/eigr/spawn?style=social)
[![join discord](https://badgen.net/badge/discord/Join%20Eigr%20on%20Discord/discord?icon=discord&label&color=blue)](https://discord.gg/2PcshvfS93)
[![twitter](https://badgen.net/badge/twitter/@eigr_io/blue?label&icon=twitter)](https://twitter.com/eigr_io)

### **[Getting Started ](https://eigr.io/spawn/docs/getting_started.html)** • **[Website](https://eigr.io/spawn)** • **[Documentation](https://eigr.io/spawn/docs/)** • **[Blog](https://eigr.io/blog/)**


## Overview

**Spawn is your actor-native service mesh for durable, stateful computing — polyglot by design, protocol-agnostic by nature.**
**Write once, run over all protocols:** Erlang-native, gRPC, or HTTP with automatic transcoding. One implementation, accessible everywhere. No boilerplate, no glue code — just clean actor abstractions that speak all your transports fluently.

Spawn simplifies the hardest part of distributed systems — **managing state at scale** — by wrapping it in an actor model that's native to modern protocols and tooling. Built by contributors to [Cloudstate](https://github.com/cloudstateio/cloudstate), it brings durable computing to your favorite language: Elixir, Java, TypeScript, Python, Rust, Go, Dart... you name it.

With Spawn, you stop worrying about infrastructure glue and start delivering business value faster.

## Why You'll Love Spawn ❤️

* **Durable Computing via Actors:** Your business logic is always-on and stateful, with snapshotting, passivation, and automatic recovery baked in.

* **Write Once, Run With All Protocols:**
Define your service once using Protobuf annotations:

  ✅ Native Erlang invocation.

  ✅ gRPC for high-performance internal APIs.

  ✅ HTTP transcoding for REST endpoints.

* **Polyglot by Design:**
Code in Elixir, Go, Java, TypeScript, Python, Rust, Lua and more. Spawn speaks your language — literally. Use the best tool for each job without sacrificing interoperability.

* **Workflows Made Easy:**
Spawn makes orchestrating complex business processes a breeze. Compose actions using **Side-effects**, chain logic with **Pipes**, or forward and routing requests seamlessly with **Forwards** — all first-class citizens in the Spawn model.

* **Projection Actors:**
Need materialized views? Spawn supports **Projection Actors** — dedicated actors that derive and maintain views of your system state in real-time. Perfect for read optimization, analytics, or integrating with external systems.

* **Seamless Scalability:**
Spawn’s actor model naturally scales to match your system’s needs, from on-premises deployments to massive cloud clusters. High availability and fault-tolerance come built-in.

* **Simplified Infrastructure:**
Forget about wiring up complex distributed systems or state management libraries. Spawn abstracts the hard parts, so you can focus on building features that deliver real value.

* **First-Class Observability:**
Out of the box, Spawn provides hooks for **metrics**, **tracing**, and **logging**. Gain full visibility into your actors and workflows to monitor health, diagnose issues, and optimize performance at scale.

Example? Here you go:

```proto
syntax = "proto3";

import "google/api/annotations.proto";
import "spawn/actors/extensions.proto";

package example.actors;

service ExampleActor {
  option (spawn.actors.actor) = {
    kind: NAMED
    stateful: true
    state_type: ".example.ExampleState"
    snapshot_interval: 60000 //optional
    deactivate_timeout: 3000 //optional
  };

  rpc Sum(.example.ValuePayload) returns (.example.SumResponse) {
    option (google.api.http) = {
      post: "/v1/example/sum"
      body: "*"
    };
  }
}
```

**Implement once, access everywhere.**

---

Example Implementation (Elixir):

```elixir
defmodule SpawnSdkExample.Actors.ExampleActor do
  use SpawnSdk.Actor, name: "ExampleActor"
  alias Example.ExampleState
  alias Example.ValuePayload
  alias Example.SumResponse

  @doc """
  Invoke with:

  alias Example.Actors.ExampleActor

  ExampleActor.sum(%Example.ValuePayload{value: 10})
  """
  action("Sum", fn %Context{state: state} = ctx, %ValuePayload{value: value} = data ->
    new_value = state.value + value

    Value.of()
    |> Value.state(%ExampleState{value: new_value})
    |> Value.response(%SumResponse{value: new_value})
  end)
end
```

**Now you can call it from multiple ways. Like from Java:**

```java
package io.eigr.spawn.java.demo;

import io.eigr.spawn.api.Spawn;
// other imports ommited

public class Main {
    public static void main(String[] args) {
        Spawn spawnSystem = new Spawn.SpawnSystem()
              .create("spawn-system")
              .build();

        spawnSystem.start();

        // Create a reference to the actor "ExampleActor"
        ActorRef exampleActor = spawnSystem.createActorRef(
            ActorIdentity.of("spawn-system", "ExampleActor")
        );

        // Prepare the input message
        ValuePayload payload = ValuePayload.newBuilder()
            .setValue(10)
            .build();

        // Invoke the "Sum" action
        Optional<SumResponse> maybeResponse = exampleActor.invoke(
            "Sum",
            payload,
            SumResponse.class
        );

        // Handle the response
        if (maybeResponse.isPresent()) {
            SumResponse response = maybeResponse.get();
            System.out.println("Sum result: " + response.getValue());
        } else {
            System.out.println("No response received from the actor.");
        }
    }
}
``` 

**Or invoke directly with grpc**
```bash
grpcurl -d '{"value":10}' \
  -plaintext localhost:9000 \
  example.actors.ExampleActor/Sum
```

**Or also via HTTP/JSON transcoding with any client http**
```bash
curl -X POST http://localhost:9000/v1/example/sum \
  -H "Content-Type: application/json" \
  -d '{"value": 10}'

```

**One contract → multiple protocols → instant productivity.**

---

## Built For Polyglot Teams 🌍

Spawn lets your team pick the right language for each service — Elixir, Java, TypeScript, Rust, Python — without reinventing the wheel. Actors are defined once and consumed seamlessly across your stack.

---

## Infrastructure? Boring. Let Spawn Handle That. 🪄

Forget about Kubernetes YAML hell, service meshes, and complex orchestration. Spawn abstracts all of that — actors get scheduled, state gets persisted, protocols get exposed — automatically with just one manifest.

Focus on what matters: **business logic.**

## How Spawn Empowers Your Team 🚀

✅ Accelerate development with consistent patterns.

✅ Scale easily across cloud and on-premises.

✅ Run resilient, stateful apps out-of-the-box.

✅ Embrace polyglot architectures without friction.

✅ Deploy with confidence, backed by a robust runtime.

---

## Meet Sepp: Our Cyberpunk Mascot 🦌

Say hello to Sepp, our cyberpunk mascot and proud [Ibex](https://alpshiking.swisshikingvacations.com/spotlight-on-the-ibex/). Sepp, hailing from the Swiss Alps, loves wandering through the Eiger mountains. Despite occasional Viking-like bluntness, he's a helpful companion who traces his lineage back to Viking times.

The name "Sepp" is indeed a German diminutive or nickname for the name Joseph. It's similar to how "Joe" is used as a nickname for Joseph in English. In German-speaking regions, it's common for Joseph to be affectionately referred to as "Sepp."

This is our little tribute to one of the creators of the Erlang programming language, [Joe Armstrong](https://en.wikipedia.org/wiki/Joe_Armstrong_(programmer)).

![Sepp Rules](docs/images/sepp-rules-254-400.png#gh-light-mode-only)
![Sepp Rules](docs/images/sepp-rules-254-400.png#gh-dark-mode-only)

---

## Dive Deeper

### 📝 Latest blogs:

* [Spawn: The Actor Mesh](https://eigr.io/blog/spawn-the-actor-mesh/)

* [Beyond Monoliths and Microservices](https://eigr.io/blog/beyond-monoliths-and-microservices/)

* [Distributed Elixir Made Easy With Spawn](https://eigr.io/blog/distributed-elixir-made-easy-with-spawn/)

### 🎙️ Talks:

* [Marcel Lanz at ACM SIGPLAN - Erlang 2021](https://www.youtube.com/watch?v=jVf0QqNb3qk)

* [Marcel Lanz at Code Beam Europe 2022](https://youtu.be/jgR7Oc_GXAg)

* [Adriano Santos at Code Beam BR 2022](https://www.youtube.com/watch?v=dXp0lyfmV_0)

* [Adriano Santos at ElugSP 2023](https://www.youtube.com/watch?v=MKTqiAtpK1E)

* [Elias Arruda at Elixir CWB](https://www.youtube.com/live/yE_uWbPEWnI?si=5L3SORG3PERZpQ4V&t=463)

* [Adriano Santos at NodeBR - API's Like a Boss](https://www.youtube.com/live/ZXJJ3BdgVBk?si=Ai0kfBrVTl6V7toT&t=373)

---

Explore how Spawn can help you meet your business objectives efficiently. Check out our [documentation](docs/index.md) and [installation guide](docs/install.md) to [get started](docs/getting_started.md).

Write less code and be happy! 🌐🚀
