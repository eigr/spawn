# Spawn

**Actor Mesh Platform**

> :warning: **Although Spawn is functional it is still a work in progress and we do not recommend it for production environments at this time.**

## Overview

Spawn is based on the sidecar proxy pattern to provide a polyglot Actor Model framework and platform.
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

The actor model, which Spawn is based on, can solve almost all the problems on this list, with Scalability, resilience, fault tolerance, and state management by far the top success stories of different known actor model implementations. So what we needed to do was add Integration Services, fast, business-oriented delivery, distributed computing, and polyglot services to the recipe so we could revolutionize software development as we know it today. 

That's exactly what we did with our platform called Eigr Functions Spawn.

Spawn takes care of the entire infrastructure layer by abstracting all the complex issues that are not part of the business domain it is intended to address.
Particularly domains such as game development, machine learning pipelines, complex event processing, real-time data ingestion, service integrations, financial or transactional services, logistics are some of the domains that can be mastered by the Eigr Functions Spawn platform.

## Spawn Architecture

Spawn takes the distribution, fault tolerance, and high concurrent capability of the Actor Model in its most famous implementation, which is the BEAM Erlang VM implementation, and adds to that the flexibility and dynamism that the sidecar pattern offers to the build cross-platform and polyglot microservice-oriented architectures.

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

* **ActorNode CRD:** A ActorNode is a cluster member application. A ActorNode by definition is a Kubernetes Deployment and will contain two containers, one containing the Actor Host Function user application and another container for the Spawn proxy which is responsible for connecting to the proxies cluster via Distributed Erlang and also for providing all the necessary abstractions for the functioning of the system such as state management, activation and passivation of actors, among other infrastructure tasks. Examples of this CRD can be found in the [examples/k8s folder](examples/k8s/node.yaml).

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

## Installation

TODO

## Getting Started

More complete guides or examples can be found on the official page or in the repositories of each SDK available.
For now let's start with a classic Hello World written with the help of the sdk for Springboot.

Let's start by defining a basic springboot maven project with the following ***pom.xml*** file:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>io.eigr</groupId>
    <artifactId>spawn-springboot-examples</artifactId>
    <version>0.1.9</version>
    <name>spawn-springboot-examples</name>
    <url>http://www.example.com</url>

    <properties>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <maven.compiler.source>1.8</maven.compiler.source>
        <maven.compiler.target>1.8</maven.compiler.target>
    </properties>

    <parent>
        <groupId>io.eigr</groupId>
        <artifactId>spawn-springboot-sdk</artifactId>
        <version>0.1.9</version>
    </parent>

    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-dependencies</artifactId>
                <version>2.7.0</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
            <dependency>
                <groupId>org.testcontainers</groupId>
                <artifactId>testcontainers-bom</artifactId>
                <version>1.17.2</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
        </dependencies>
    </dependencyManagement>

    <dependencies>
        <dependency>
            <groupId>io.eigr</groupId>
            <artifactId>spawn-springboot-starter</artifactId>
            <version>0.1.9</version>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-webflux</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>

        <dependency>
            <groupId>org.testcontainers</groupId>
            <artifactId>testcontainers</artifactId>
            <scope>test</scope>
        </dependency>

        <dependency>
            <groupId>junit</groupId>
            <artifactId>junit</artifactId>
            <version>4.13.2</version>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <extensions>
            <extension>
                <groupId>kr.motd.maven</groupId>
                <artifactId>os-maven-plugin</artifactId>
                <version>1.6.2</version>
            </extension>
        </extensions>

        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <configuration>
                    <source>1.8</source>
                    <target>1.8</target>
                </configuration>
            </plugin>

            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>

            <plugin>
                <groupId>org.xolstice.maven.plugins</groupId>
                <artifactId>protobuf-maven-plugin</artifactId>
                <version>0.6.1</version>
                <configuration>
                    <protocArtifact>com.google.protobuf:protoc:3.19.2:exe:${os.detected.classifier}</protocArtifact>
                    <pluginId>grpc-java</pluginId>
                    <pluginArtifact>io.grpc:protoc-gen-grpc-java:1.47.0:exe:${os.detected.classifier}</pluginArtifact>
                </configuration>
                <executions>
                    <execution>
                        <goals>
                            <goal>compile</goal>
                            <goal>compile-custom</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>

            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-surefire-plugin</artifactId>
                <version>2.7</version>
            </plugin>

            <plugin>
                <artifactId>maven-dependency-plugin</artifactId>
                <version>2.5.1</version>
                <executions>
                    <execution>
                        <id>getClasspathFilenames</id>
                        <goals>
                            <!-- provides the jars of the classpath as properties inside of maven
                                 so that we can refer to one of the jars in the exec plugin config below -->
                            <goal>properties</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>

            <plugin>
                <groupId>com.google.cloud.tools</groupId>
                <artifactId>jib-maven-plugin</artifactId>
                <version>3.1.4</version>
                <executions>
                    <execution>
                        <phase>package</phase>
                        <goals>
                            <goal>build</goal>
                        </goals>
                    </execution>
                </executions>
                <configuration>
                    <to>
                        <image>my-dockerhub-repo/spawn-springboot-examples</image>
                    </to>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
```

As Spawn depends on the types of data exchanged between actors being defined via Protobuf types we will have to create a folder to store such files in our project. In maven projects this can be done by creating a folder under ***src/main/proto***. In our example we will create the folders ***src/main/proto/io/eigr/spawn/example*** and inside the example folder we will create the file **example.proto** with the following content:

```proto
syntax = "proto3";

package io.eigr.spawn.example;

option java_multiple_files = true;
option java_package = "io.eigr.spawn.example";
option java_outer_classname = "ExampleProtos";

message MyState {
  int32 value = 1;
}

message MyBusinessMessage {
  int32 value = 1;
}
```

As you can see, we have defined two types of messages, one that will be used to store the state of our actor to be created later, and the other to be able to transmit business information that will be used in our actor's methods.

Now we can start writing some code. Let's start by defining our Actor class:

```java
package io.eigr.spawn.example;

import io.eigr.spawn.springboot.starter.ActorContext;
import io.eigr.spawn.springboot.starter.Value;
import io.eigr.spawn.springboot.starter.annotations.ActorEntity;
import io.eigr.spawn.springboot.starter.annotations.Command;
import lombok.extern.log4j.Log4j2;

import java.util.Optional;

@Log4j2
@ActorEntity(name = "joe", stateType = MyState.class, snapshotTimeout = 10000, deactivatedTimeout = 50000)
public class JoeActor {

    @Command
    public Value get(ActorContext<MyState> context) {
        log.info("Received invocation. Context: {}", context);
        if (context.getState().isPresent()) {
            MyState state = context.getState().get();

            return Value.ActorValue.<MyState, MyBusinessMessage>at()
                    .state(state)
                    .value(MyBusinessMessage.newBuilder()
                            .setValue(state.getValue())
                            .build())
                    .reply();
        }

        return Value.ActorValue.at()
                .empty();
    }

    @Command(name = "sum", inputType = MyBusinessMessage.class)
    public Value sum(MyBusinessMessage msg, ActorContext<MyState> context) {
        log.info("Received invocation. Message: {}. Context: {}", msg, context);

        int value = 1;
        if (context.getState().isPresent()) {
            log.info("State is present and value is {}", context.getState().get());
            Optional<MyState> oldState = context.getState();
            value = oldState.get().getValue() + msg.getValue();
        } else {
            log.info("State is NOT present. Msg getValue is {}", msg.getValue());
            value = msg.getValue();
        }

        log.info("New Value is {}", value);
        MyBusinessMessage resultValue = MyBusinessMessage.newBuilder()
                .setValue(value)
                .build();

        return Value.ActorValue.at()
                .value(resultValue)
                .state(updateState(value))
                .reply();
    }

    private MyState updateState(int value) {
        return MyState.newBuilder()
                .setValue(value)
                .build();
    }

}

```

The code itself is somewhat self explanatory but you can check out the Springboot SDK documentation if you want to know all the details. Basically we define an Actor (our class because we are using Java which is object oriented) which in turn has two methods, one that only returns the value of the current state of our actor and another method that receives the current state but also receives our message of business. 

Note that the state of an actor will always be passed as an argument through the Context type, while the business message will always be passed directly as the method's first argument.

The sum method, in turn, receives the business message, extracts the value passed and adds it to the value of the actor's current state.

Now that we've defined our first actor, it's time to write our Main class:

```java
package io.eigr.spawn.example;

import io.eigr.spawn.springboot.starter.SpawnSystem;
import io.eigr.spawn.springboot.starter.autoconfigure.EnableSpawn;
import lombok.extern.log4j.Log4j2;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.Bean;

@Log4j2
@EnableSpawn
@SpringBootApplication
@EntityScan("io.eigr.spawn.example")
public class App {
    public static void main(String[] args) {SpringApplication.run(App.class, args);}

    @Bean
    public CommandLineRunner commandLineRunner(ApplicationContext ctx) {
        return args -> {
            SpawnSystem actorSystem = ctx.getBean(SpawnSystem.class);
            log.info("Let's invoke some Actor");
            for (int i = 0; i < 10000; i++) {
                MyBusinessMessage arg = MyBusinessMessage.newBuilder()
                        .setValue(i)
                        .build();

                MyBusinessMessage sumResult = (MyBusinessMessage) actorSystem.invoke("joe", "sum", arg, MyBusinessMessage.class);
                log.info("Actor invoke Sum Actor Action value result: {}", sumResult.getValue());
            }

            MyBusinessMessage getResult = (MyBusinessMessage) actorSystem.invoke("joe", "get", MyBusinessMessage.class);
            log.info("Actor invoke Get Actor Action value result: {}", getResult.getValue());
        };
    }
}
```

Once again the code is self explanatory and will not be discussed in detail here. Just know that what we did was start our application telling Spring that it is a Spawn Host Actor Function app and that after starting we will perform a series of invocations to our previously defined actor. In turn, at each invocation the state will be stored by the actor and even if the application is restarted, the actor will return from the point at which it was before being turned off.

To proceed, just create a container and send it to a container registry that will be accessible via kubernetes in the future. This can be done by executing the following command in the application directory via terminal:

```shell
mvn install
```

This command will compile the maven application and thanks to the jib maven plugin it will also publish the container image in your dockerhub registry :)

Now that we have created our container containing our Actor Host Function we must deploy it in a Kubernetes cluster that has the Eigr Functions Controller installed (See more about this process in the section on installation).

In a directory of your choice, create a file called ***system.yaml*** with the following content:

```yaml
---
apiVersion: spawn.eigr.io/v1
kind: ActorSystem
metadata:
  name: spawn-system
  namespace: default
spec:
  storage:
    type: InMemory
```

This file will be responsible for creating a system of actors in the cluster.

Now create a new file called ***node.yaml*** with the following content:

```yaml
---
apiVersion: spawn.eigr.io/v1
kind: ActorNode
metadata:
  name: my-first-app
  system: spawn-system
  namespace: default
spec:
  function:
    image: my-dockerhub-repo/spawn-springboot-examples:latest
```

This file will be responsible for deploying your host function and actors in the cluster.
Now that the files have been defined, we can apply them to the cluster:

```shell
kubectl apply -f system.yaml
kubectl apply -f node.yaml
```

After that, just check your actors with:

```shell
kubectl get actornodes
```

## Local Development

Run:

```shell
PROXY_DATABASE_TYPE=mysql SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= iex --name spawn_a2@127.0.0.1 -S mix
```

Tests:

```shell
MIX_ENV=test PROXY_DATABASE_TYPE=mysql PROXY_HTTP_PORT=9001 SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= elixir --name spawn@127.0.0.1 -S mix test
```

For more information on how to collaborate or even to get to know the project structure better, go to our [contributor guide](CONTRIBUTING.md)