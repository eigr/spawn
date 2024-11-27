# Java Workflows

Spawn has several mechanisms to facilitate integration between your actors or your application with the outside world. Below are some types of integration that Spawn provides:

## Broadcast

Actors in Spawn can subscribe to a thread and receive, as well as broadcast, events for a given thread.

To consume from a topic, you just need to configure the Actor using the channel option as follows:

```java
return new NamedActorBehavior(
  name("JoeActor"),
  channel("test.channel"),
);
```
In the case above, the Actor `JoeActor` was configured to receive events that are forwarded to the topic called `test.channel`.

To produce events in a topic, just use the Broadcast Workflow. The example below demonstrates a complete example of 
producing and consuming events. In this case, the same actor is the event consumer and producer, but in a more realistic scenario, 
different actors would be involved in these processes.

```Java
package io.eigr.spawn.java.demo.actors;

import io.eigr.spawn.api.actors.ActorContext;
import io.eigr.spawn.api.actors.StatefulActor;
import io.eigr.spawn.api.actors.Value;
import io.eigr.spawn.api.actors.behaviors.ActorBehavior;
import io.eigr.spawn.api.actors.behaviors.BehaviorCtx;
import io.eigr.spawn.api.actors.behaviors.NamedActorBehavior;
import io.eigr.spawn.api.actors.workflows.Broadcast;
import io.eigr.spawn.api.actors.ActionBindings;
import domain.Reply;
import domain.Request;
import domain.State;

import static io.eigr.spawn.api.actors.behaviors.ActorBehavior.*;

public final class LoopActor implements StatefulActor<State> {

    @Override
    public ActorBehavior configure(BehaviorCtx context) {
        return new NamedActorBehavior(
                name("LoopActor"),
                channel("test.channel"),
                action("SetLanguage", ActionBindings.of(Request.class, this::setLanguage))
        );
    }

    private Value setLanguage(ActorContext<State> context, Request msg) {
        return Value.at()
                .flow(Broadcast.to("test.channel", "setLanguage", msg))
                .response(Reply.newBuilder()
                        .setResponse("Hello From Erlang")
                        .build())
                .state(updateState("erlang"))
                .reply();
    }

    // ...
}
```

## Side Effects

Actors can also emit side effects to other Actors as part of their response.
See an example:

```Java
package io.eigr.spawn.java.demo.actors;

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
        ActorRef sideEffectReceiverActor = ctx.getSpawnSystem()
                .createActorRef(ActorIdentity.of("spawn-system", "MikeFriendActor", "MikeParentActor"));

        return Value.at()
                .flow(SideEffect.to(sideEffectReceiverActor, "setLanguage", msg))
                .response(Reply.newBuilder()
                        .setResponse(String.format("Hi %s. Hello From Java", msg.getLanguage()))
                        .build())
                .state(updateState(msg.getLanguage()))
                .noReply();
    }

    // ....
}
```

Side effects such as broadcast are not part of the response flow to the caller. They are request-asynchronous events that 
are emitted after the Actor's state has been saved in memory.

## Forward

Actors can route some actions to other actors as part of their response. For example, sometimes you may want another 
Actor to be responsible for processing a message that another Actor has received. We call this forwarding, 
and it occurs when we want to forward the input argument of a request that a specific Actor has received to the input of 
an action in another Actor.

See an example:

```Java
package io.eigr.spawn.java.demo.actors;

import io.eigr.spawn.api.actors.ActionBindings;
import io.eigr.spawn.api.actors.ActorContext;
import io.eigr.spawn.api.actors.StatefulActor;
import io.eigr.spawn.api.actors.Value;
import io.eigr.spawn.api.actors.behaviors.ActorBehavior;
import io.eigr.spawn.api.actors.behaviors.BehaviorCtx;
import io.eigr.spawn.api.actors.behaviors.NamedActorBehavior;
import domain.Reply;
import domain.Request;
import domain.State;

import static io.eigr.spawn.api.actors.behaviors.ActorBehavior.*;

public final class RoutingActor implements StatefulActor<State> {

    @Override
    public ActorBehavior configure(BehaviorCtx context) {
        return new NamedActorBehavior(
                name("RoutingActor"),
                action("SetLanguage", ActionBindings.of(Request.class, this::setLanguage))
        );
    }

    private Value setLanguage(ActorContext<State> context, Request msg) {
        ActorRef forwardedActor = ctx.getSpawnSystem()
                .createActorRef(ActorIdentity.of("spawn-system", "MikeFriendActor", "MikeActor"));

        return Value.at()
                .flow(Forward.to(forwardedActor, "setLanguage"))
                .noReply();
    }
}
```

## Pipe

Similarly, sometimes we want to chain a request through several processes. For example forwarding an actor's computational 
output as another actor's input. There is this type of routing we call Pipe, as the name suggests, a pipe forwards what 
would be the response of the received request to the input of another Action in another Actor.
In the end, just like in a Forward, it is the response of the last Actor in the chain of routing to the original caller.

Example:

```Java
package io.eigr.spawn.java.demo.actors;

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

public final class PipeActor implements StatefulActor<State> {

    @Override
    public ActorBehavior configure(BehaviorCtx context) {
        return new NamedActorBehavior(
                name("PipeActor"),
                action("SetLanguage", ActionBindings.of(Request.class, this::setLanguage))
        );
    }

    private Value setLanguage(ActorContext<State> context, Request msg) {
        ActorRef pipeReceiverActor = ctx.getSpawnSystem()
                .createActorRef(ActorIdentity.of("spawn-system", "JoeActor"));

        return Value.at()
                .response(Reply.newBuilder()
                        .setResponse("Hello From Java")
                        .build())
                .flow(Pipe.to(pipeReceiverActor, "someAction"))
                .state(updateState("java"))
                .noReply();
    }

    // ...
}
```

Forwards and pipes do not have an upper thread limit other than the request timeout.

[Next: Projections](projections.md)

[Previous: Actor Invocation](actor_invocation.md)