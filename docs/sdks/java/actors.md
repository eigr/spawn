# Java Actors

Spawn defines the following types of Actors:

* **Named Actors**: Named actors are actors whose name is defined at compile time. They also behave slightly differently 
Then unnamed actors and pooled actors. Named actors when they are defined with the stateful parameter equal to True are 
immediately instantiated when they are registered at the beginning of the program, they can also only be referenced by 
the name given to them in their definition.

* **Unnamed Actors**: Unlike named actors, unnamed actors are only created when they are named at runtime, that is, 
during program execution. Otherwise, they behave like named actors.

* **Pooled Actors**: Pooled Actors, as the name suggests, are a collection of actors that are grouped under the same name 
assigned to them at compile time. Pooled actors are generally used when higher performance is needed and are also 
recommended for handling serverless loads.

## Stateless Actors

In addition to these types, Spawn also allows the developer to choose Stateful actors, who need to maintain the state, 
or Stateless, those who do not need to maintain the state.
For this the developer just needs to make extend of the correct base interface. For example, I could declare a Serverless Actor using the following code:

```java
package io.eigr.spawn.java.demo.actors;

import io.eigr.spawn.api.actors.ActionBindings;
import io.eigr.spawn.api.actors.ActorContext;
import io.eigr.spawn.api.actors.StatelessActor;
import io.eigr.spawn.api.actors.Value;
import io.eigr.spawn.api.actors.behaviors.ActorBehavior;
import io.eigr.spawn.api.actors.behaviors.BehaviorCtx;
import io.eigr.spawn.api.actors.behaviors.NamedActorBehavior;
import domain.Reply;
import domain.Request;

import static io.eigr.spawn.api.actors.behaviors.ActorBehavior.action;
import static io.eigr.spawn.api.actors.behaviors.ActorBehavior.name;

public final class StatelessNamedActor implements StatelessActor {

    @Override
    public ActorBehavior configure(BehaviorCtx context) {
        return new NamedActorBehavior(
                name("StatelessNamedActor"),
                action("SetLanguage", ActionBindings.of(Request.class, this::setLanguage))
        );
    }

    private Value setLanguage(ActorContext<?> context, Request msg) {
        return Value.at()
                .response(Reply.newBuilder()
                        .setResponse(String.format("Hi %s. Hello From Java", msg.getLanguage()))
                        .build())
                .reply();
    }
}

```

## Stateful Actors

Spawn allows the state of your actors to be managed by the runtime itself. This eliminates the need for developers to deal with databases, caches, and other issues related to managing the state of their applications.
To define a stateful actor, the developer simply implements the StatefulActor interface, as shown in the following example:

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

Understand that the current state becomes accessible to the programmer through the ActorContext object passed as an argument to the method and that a new updated state is reported to the Spawn proxy in the Value object.

Other than that, for both Stateless and Stateful actors, the same Named, UnNamed types are supported. Just use the NamedActorBehavior or UnNamedActorBehavior class inside a `configure` method.

## Considerations about Spawn actors

Another important feature of Spawn Actors is that the lifecycle of each Actor is managed by the platform itself. 
This means that an Actor will exist when it is invoked and that it will be deactivated after an idle time in its execution. 
This pattern is known as [Virtual Actors](#virtual-actors) but Spawn's implementation differs from some other known 
frameworks like [Orleans](https://www.microsoft.com/en-us/research/project/orleans-virtual-actors/) or 
[Dapr](https://docs.dapr.io/developing-applications/building-blocks/actors/actors-overview/) 
by defining a specific behavior depending on the type of Actor (named, unnamed, pooled, and etc...).

For example, named actors are instantiated the first time as soon as the host application registers them with the Spawn proxy. 
Whereas unnamed and pooled actors are instantiated the first time only when they receive their first invocation call.

[Next: Actor Invocation](actor_invocation.md)

[Previous: Getting Started](getting_started.md)