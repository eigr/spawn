# Java Getting Started

First we need to install [Spawn CLI tool](../../install.md#install) to create a new Java project.

```shell
curl -sSL https://github.com/eigr/spawn/releases/download/latest/install.sh | sh
```
Now you will need to fill in the data for groupId, artifactId, version, and package. 
Let's call our maven artifact spawn-java-demo. The output of this command will be similar to the output below

```shell
spawn new java spawn-java-demo --group-id=io.eigr.spawn --artifact-id=spawn-java-demo --version=1.0.0 --package=io.eigr.spawn.java.demo
```
Now it is necessary to download the dependencies via Maven:

```shell
cd spawn-java-demo && mvn install
```

So far it's all pretty boring and not really Spawn related, so it's time to start playing for real.
The first thing we're going to do is define a place to put our protobuf files. 

```shell
touch src/main/proto/actors/domain.proto
```

And let's populate this file with the following content:

```protobuf
syntax = "proto3";

package domain;
// Due to the dynamic nature of spawn we are required to define the java package 
// as being the same as the protobuf package name.
option java_package = "domain";
// Generating the java classes in multiple files is mandatory for the process to work correctly.
option java_multiple_files = true;

message State {
   repeated string languages = 1;
}

message Request {
   string language = 1;
}

message Reply {
   string response = 1;
}

service JoeActor {
   rpc SetLanguage(Request) returns (Reply);
}
```

> **_NOTE:_** Due to the dynamic nature of spawn we are required to define the java package
> as being the same as the protobuf package name. Also generating the java classes in multiple files 
> is mandatory for the process to work correctly.

We must compile this file using the protoc utility. In the root of the project type the following command:

```shell
mvn protobuf:compile
```

Now in the spawn-java-demo folder we will create our first Java file containing the code of our Actor.

```shell
touch src/main/java/io/eigr/spawn/java/demo/Joe.java
```

Populate this file with the following content:

```Java
package io.eigr.spawn.java.demo;

import io.eigr.spawn.api.actors.ActorContext;
import io.eigr.spawn.api.actors.StatefulActor;
import io.eigr.spawn.api.actors.Value;
import io.eigr.spawn.api.actors.behaviors.ActorBehavior;
import io.eigr.spawn.api.actors.behaviors.BehaviorCtx;
import io.eigr.spawn.api.actors.behaviors.NamedActorBehavior;
import io.eigr.spawn.api.actors.ActionBindings;
import domain.Reply;
import domain.Request;
import domain.State;

import static io.eigr.spawn.api.actors.behaviors.ActorBehavior.*;

public final class JoeActor implements StatefulActor<State> {

    @Override
    public ActorBehavior configure(BehaviorCtx context) {
        return new NamedActorBehavior(
                name("JoeActor"),
                channel("test.channel"),
                action("SetLanguage", ActionBindings.of(Request.class, this::setLanguage))
        );
    }

    private Value setLanguage(ActorContext<State> context, Request msg) {
        if (context.getState().isPresent()) {
            //Do something with previous state
        }

        return Value.at()
                .response(Reply.newBuilder()
                        .setResponse(String.format("Hi %s. Hello From Java", msg.getLanguage()))
                        .build())
                .state(updateState(msg.getLanguage()))
                .reply();
    }

    private State updateState(String language) {
        return State.newBuilder()
                .addLanguages(language)
                .build();
    }
}
```

## Dissecting the code

***Class Declaration***

```java
package io.eigr.spawn.java.demo;

import io.eigr.spawn.api.actors.StatefulActor;
import domain.State;

public final class JoeActor implements StatefulActor<State> {
 // ...
}
```

The `JoeActor` class implements `StatefulActor<State>` interface. `StatefulActor` is a generic interface provided by the Spawn API, 
which takes a type parameter for the state. In this case, the state type is `domain.State` 
defined in above protobuf file.

***Configure Actor Behavior***

```java
public final class JoeActor implements StatefulActor<State> {
   @Override
   public ActorBehavior configure(BehaviorCtx context) {
      return new NamedActorBehavior(
              name("JoeActor"),
              channel("test.channel"),
              action("SetLanguage", ActionBindings.of(Request.class, this::setLanguage))
      );
   }
}
```

This `configure` method is overridden from `StatefulActor` and is used to configure the actor's behavior.

* `name("JoeActor")`: Specifies the name of the actor. Note that the Actor name has the same name as the service declared 
                      in protobuf. This is not a coincidence, the Spawn proxy uses the protobuf metadata to map **actors** and 
                      their **actions** and therefore these names should correctly reflect this behavior.
* `channel("test.channel")`: Specifies the channel the actor listens to. See [Broadcast](#broadcast) section below.
* `action("SetLanguage", ActionBindings.of(Request.class, this::setLanguage))`: Binds the `SetLanguage` action to the `setLanguage` method, 
                                                                                which takes a `Request` message as input. 
                                                                                Where the second parameter of `ActionBindings.of(type, lambda)` method is a lambda.

***Handle request***

```java
public final class JoeActor implements StatefulActor<State> {
   //
   private Value setLanguage(ActorContext<State> context, Request msg) {
      if (context.getState().isPresent()) {
         // Do something with the previous state
      }

      return Value.at()
              .response(Reply.newBuilder()
                      .setResponse(String.format("Hi %s. Hello From Java", msg.getLanguage()))
                      .build())
              .state(updateState(msg.getLanguage()))
              .reply();
   }
}
```

This method `setLanguage` is called when the `SetLanguage` action is invoked. It takes an `ActorContext<State>` and a `Request` message as parameters.

* `context.getState().isPresent()`: Checks if there is a previous existing state.
* The method then creates a new `Value` response:
  * `response(Reply.newBuilder().setResponse(...).build())`: Builds a `Reply` object with a response message.
  * `state(updateState(msg.getLanguage()))`: Updates the state with the new language.
  * `reply()`: Indicates that this is a reply message. You could also ignore the reply if you used a `noReply()` method instead of the `reply` method.

Ok now with our Actor properly defined, we just need to start the SDK correctly. Create another file called App.java 
to serve as your application's entrypoint and fill it with the following content:

```Java
package io.eigr.spawn.java.demo;

import io.eigr.spawn.api.Spawn;

public class App {
   public static void main(String[] args) throws Exception {
      Spawn spawnSystem = new SpawnSystem()
              .create("spawn-system")
              .withActor(Joe.class)
              .build();

      spawnSystem.start();
   }
}
```

Or passing transport options like:

```Java
package io.eigr.spawn.java.demo;

import io.eigr.spawn.api.Spawn;
import io.eigr.spawn.api.TransportOpts;

public class App {
   public static void main(String[] args) throws Exception {
      TransportOpts opts = TransportOpts.builder()
              .port(8091)
              .proxyPort(9003)
              .executor(Executors.newVirtualThreadPerTaskExecutor()) // If you use java above 19 and use the --enable-preview flag when running the jvm
              .build();

      Spawn spawnSystem = new SpawnSystem()
              .create("spawn-system")
              .withActor(Joe.class)
              .withTransportOptions(opts)
              .build();

      spawnSystem.start();
   }
}
```

Then:

```shell
mvn compile && mvn package && java -jar target/spawn-java-demo-1.0-SNAPSHOT.jar 
```

But of course you will need to locally run the Elixir proxy which will actually provide all the functionality for your Java application. 

```shell
spawn dev run -p src/main/proto -s spawn-system -W
```

Spawn is based on kubernetes and containers, so you will need to generate a docker container for your application.
There are many ways to do this, one of them is by adding Maven's jib plugin. 
Add the following lines to your plugin's section in pom.xml file:

```xml
<plugin>
    <groupId>com.google.cloud.tools</groupId>
    <artifactId>jib-maven-plugin</artifactId>
    <version>3.3.2</version>
    <configuration>
        <to>
            <image>your-repo-here/spawn-java-demo</image>
        </to>
    </configuration>
</plugin>
```

finally you will be able to create your container by running the following command in the root of your project:

```shell
mvn compile jib:build
```

[Next: Actors](actors.md)

[Previous: SDKs](../../sdks.md)