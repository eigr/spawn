# Actor Invocation

To invoke an actor named like the one we defined in section [Getting Started](getting_started.md) we could do as follows:

```Java
ActorRef joeActor = spawnSystem.createActorRef(ActorIdentity.of("spawn-system", "JoeActor"));
        
Request msg = Request.newBuilder()
       .setLanguage("erlang")
       .build();
        
Optional<Reply> maybeResponse = joeActor.invoke("setLanguage", msg, Reply.class);
Reply reply = maybeResponse.get();
```

More detailed in complete main class:

```java
package io.eigr.spawn.java.demo;

import io.eigr.spawn.api.Spawn;
import io.eigr.spawn.api.Spawn.SpawnSystem;
import io.eigr.spawn.api.ActorIdentity;
import io.eigr.spawn.api.ActorRef;
import io.eigr.spawn.api.TransportOpts;
import io.eigr.spawn.api.exceptions.SpawnException;
import domain.Reply;
import domain.Request;

public class App {
   public static void main(String[] args) throws SpawnException {
      Spawn spawnSystem = new SpawnSystem()
              .create("spawn-system")
              .withActor(Joe.class)
              .withTransportOptions(
                      TransportOpts.builder()
                              .port(8091)
                              .proxyPort(9003)
                              .build()
              )
              .build();

      spawnSystem.start();

      ActorRef joeActor = spawnSystem.createActorRef(ActorIdentity.of("spawn-system", "JoeActor"));

      Request msg = Request.newBuilder()
              .setLanguage("erlang")
              .build();
     
      joeActor.invoke("setLanguage", msg, Reply.class)
              .ifPresent(response ->  log.info("Response is: {}", response));
   }
}
```

In the above case we invoke an actor of type Named. The following section demonstrates how to invoke actors of type Unnamed.

## Call Unnamed Actors

Unnamed actors are equally simple to invoke. All that is needed is to inform the `parent` parameter which refers to the 
name given to the actor that defines the ActorRef template.

To better exemplify, let's first show the Actor's definition code and later how we would call this actor with a concrete 
name at runtime:

```java
package io.eigr.spawn.test.actors;

import io.eigr.spawn.api.actors.ActionBindings;
import io.eigr.spawn.api.actors.ActorContext;
import io.eigr.spawn.api.actors.StatefulActor;
import io.eigr.spawn.api.actors.Value;
import io.eigr.spawn.api.actors.behaviors.ActorBehavior;
import io.eigr.spawn.api.actors.behaviors.BehaviorCtx;
import io.eigr.spawn.api.actors.behaviors.UnNamedActorBehavior;
import domain.Reply;
import domain.Request;
import domain.State;

import static io.eigr.spawn.api.actors.behaviors.ActorBehavior.*;

public final class MikeActor implements StatefulActor<State> {

    @Override
    public ActorBehavior configure(BehaviorCtx context) {
        return new UnNamedActorBehavior(
                name("MikeActor"),
                snapshot(1000),
                deactivated(60000),
                action("SetLanguage", ActionBindings.of(Request.class, this::setLanguage))
        );
    }

    private Value setLanguage(ActorContext<State> context, Request msg) {
        return Value.at()
                .response(Reply.newBuilder()
                        .setResponse(String.format("Hi %s. Hello From Java", msg.getLanguage()))
                        .build())
                .state(updateState(msg.getLanguage()), true)
                .reply();
    }

    // ...
}
```

So you could define and call this actor at runtime like this:

```Java
ActorRef mike = spawnSystem.createActorRef(ActorIdentity.of("spawn-system", "MikeInstanceActor", "MikeActor"));
        
Request msg = Request.newBuilder()
       .setLanguage("erlang")
       .build();

Optional<Reply> maybeResponse = mike.invoke("setLanguage", msg, Reply.class);
Reply reply = maybeResponse.get();
```

The important part of the code above is the following snippet:

```Java
ActorRef mike = spawnSystem.createActorRef(ActorIdentity.of("spawn-system", "MikeInstanceActor", "MikeActor"));
```

These tells Spawn that this actor will actually be named at runtime. The name parameter with value "MikeInstanceActor" 
in this case is just a reference to "MikeActor" Actor that will be used later 
so that we can actually create an instance of the real Actor.

## Async

Basically Spawn can perform actor functions in two ways. Synchronously, where the callee waits for a response, 
or asynchronously, where the callee doesn't care about the return value of the call. 
In this context we should not confuse Spawn's asynchronous way with Java's concept of async like Promises because async for Spawn is 
just a fire-and-forget call.

Therefore, to call an actor's function asynchronously, just use the invokeAsync method:

```Java
mike.invokeAsync("setLanguage", msg);
```

## Timeouts

It is possible to change the request waiting timeout using the invocation options as below:

```Java
package io.eigr.spawn.java.demo;

// omitted imports for brevity

public class App {
   public static void main(String[] args) {
      Spawn spawnSystem = new Spawn.SpawnSystem()
              .create("spawn-system")
              .withActor(Joe.class)
              .build();

      spawnSystem.start();

      ActorRef joeActor = spawnSystem.createActorRef(ActorIdentity.of("spawn-system", "JoeActor"));

      Request msg = Request.newBuilder()
              .setLanguage("erlang")
              .build();

      InvocationOpts opts = InvocationOpts.builder()
              .timeoutSeconds(Duration.ofSeconds(30))
              .build();
      
      Optional<Reply> maybeResponse = joeActor.invoke("setLanguage", msg, Reply.class, opts);
   }
}
```

[Next: Workflows](workflows.md)

[Previous: Actors](actors.md)