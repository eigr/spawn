# History

The Eigr Spawn project is based on ideas and concepts that where brought to life with the Cloudstate open-source project. In the following section we describe why the Eigr Spawn project looks similar to Cloudstate and why it was started at all.

## The Legacy of Cloudstate

Cloudstate is an open-source project that was started by Lightbend Inc. in 2019 and took the challenge to solve one of the harder problems of the classical FaaS model (Function-as-a-Service) in serverless computing. Serverless 1.0, as the project stated, lacks the concept to manage state in the world of stateless functions and therefore burdens the user to integrate some form of state-management into an inherently stateless architecture.

Cloudstate started with two promises to "pave the way for Serverless 2.0" to solve that problem:

    A standards effort—defining a specification, protocol between the user functions and the backend, and a TCK.
    A reference implementation–implementing the backend and a set of client API libraries in different languages.

## A Project in Limbo

The decision to fork the Cloudstate project was based on a shift in focus since about mid 2020 of its initiating organization Lightbend Inc. to pursue a Serverless offering of the Cloudstate technology. This focus left the open source project and its community in limbo with no clear roadmap and kept its further development locked where nothing but a fork was an option to further work on the vision Cloudstate promised to solve.

The members of the eigr.io open-source project have been very supportive and engaged early on in the Cloudstate project. Also, the majority of the Cloudstate "User Language Support Libraries" have been initiated and implemented by that community. The previously known as [Eigr Functions project](https://github.com/eigr/massa) will build on that work, enhance it, be an open and welcoming community and going forward implementing the original vision of Cloudstate.
Protocol compatibility and its future

Eigr Functions attempted to be compatible with the Cloudstate protocol. Our project forked Cloudstate's "User Language Support Libraries" to continue working on its implementations. Likewise, the original TCK, as envisioned, would be used to verify compatibility with the protocol and the new Eigr Functions polyglot language SDKs.

A prerequisite for keeping compatibility intact was that the currently obsolete Cloudstate project was willing to adopt changes in the future if necessary. Its use in Akka Serverless, although developed as a proprietary and commercial product, has long since broken away from the Cloudstate protocol. We didn't know if the open source Akka Serverless SDKs would be supported by Cloudstate again. However, the eigr project has set out to welcome future compatibility.

## The birth of Spawn

After realizing that Lightbend had no intention of maintaining compatibility with the Cloudstate protocol in the long term, we decided that we needed to follow our own path. That's when we decided to completely revamp our proxy and our Kubernetes controller into something completely new.
We fully embraced the Erlang way and Spawn was born, a simpler and much more versatile approach to building applications based on the precepts of durable computing.

## Why on the BEAM?

The decision to switch technical grounds was mainly guided by the fact that Cloudstate went into hibernation mode, and it made no sense to re-implement the Cloudstate proxy in Scala and use Akka Cluster itself again. Going with Go or Rust would have been an option. But we realized early on, that competing in a way with the excellent work of the Akka team we would not come soon with a replacement of all what Akka and Akka Cluster provide in the context of this project.

With a modern functional language like Elixir and the Erlang Ecosystem in general in its excellent shape these days, it came to us, why not to use the BEAM, Elixir and Erlang/OTP as the technical ground for our new project. Even if Erlang or Elixir were not so mainstream languages to use, the technology and especially the language in which the service proxy is written is irrelevant in the context of enabling a cloud-native and therefore polyglot serverless runtime.

Eigr Spawn being based on Erlang/OTP and running on the BEAM is an excellent fit for a serverless runtime to be built on. The "message in, message out" pattern for a FaaS implementation, as well as the requirements to run actually virtual actors in a distributed system is right spot on what OTP, the BEAM and Erlang are all about.

[Previous: Contributing](../CONTRIBUTING.md)