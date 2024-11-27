# Overview

Since UC Berkeley published its [Cloud Programming Simplified: A Berkeley View on
Serverless Computing](https://www2.eecs.berkeley.edu/Pubs/TechRpts/2019/EECS-2019-3.pdf) in the year of 2019, several solutions for Stateful Serverless and Durable Computing are emerging on the market.
Originally coming from some contributors to the [Cloudstate](https://github.com/cloudstateio/cloudstate), Spawn stands as the Erlang world's answer to the challenges of durable serverless computing. 

Unlike serverless runtimes hidden in cloud providers' black boxes, Spawn is an open-source serverless runtime designed for both cloud and on-premises environments. Powered by [BEAM](https://www.erlang.org/blog/a-brief-beam-primer/) and [ERTS](https://www.erlang.org/doc/apps/erts/), Spawn offers a polyglot programming model for crafting versatile applications. It's **BEAM** for all.

Explore the potential of Erlang, regardless of your preferred programming language, to swiftly accomplish your business objectives. Check out our [documentation](docs/index.md) to [get started](docs/getting_started.md).

## Demystifying the Serverless Computing Model

> **_Tip:_** Serverless is not just FaaS

Serverless computing is a cloud computing execution model characterized by the automatic management of infrastructure, allowing developers to focus solely on code without the need to provision or manage servers explicitly. While commonly associated with cloud services, it's important to note that some serverless products operate independently of specific cloud providers, like Spawn. In these cases, the fundamental principles of automatic scaling, pay-per-execution pricing, and the abstraction of infrastructure complexities still apply, offering developers a serverless experience without exclusive reliance on a particular cloud platform.

While serverless is often associated with Function as a Service (FaaS), where functions are the unit of deployment and execution, serverless computing can extend beyond just FaaS. In a broader sense, serverless includes services like backend-as-a-service (BaaS) and other cloud offerings where developers can build and deploy applications without dealing with the underlying infrastructure.

The key features of serverless computing include automatic scaling, pay-per-execution pricing, and a shift of operational responsibilities from the developer to the cloud provider or underlying runtime. Developers can focus more on writing code and implementing business logic, leaving the infrastructure management, scaling, and maintenance to the upper runtime.

Spawn extends this Serverless computing model by considering that there is an infrastructure layer in all application code, such as state management, configuration management, integration flows with other applications, connection pooling, and so on, and that this code infrastructure must also be managed by the runtime, freeing the developer so that he can focus much more on his business objectives directly.

This also brings security to CEOs and CTOs as well as product managers that the central objectives of their companies will be achieved within a shorter period of time, thus increasing their competitiveness against their competitors. This without compromising technical quality and scalability to support your products running in production.

[Back to Index](index.md)

[Next: Architecture](architecture.md)

[Previous: Index](index.md)