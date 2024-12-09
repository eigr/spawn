# Node Actors

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

## Named Actor

In this example we are creating an actor in a Named way, that is, it is a known actor at compile time. Or a 'global' actor with only one name.

```TS
import spawn, { ActorContext, Kind, Value } from '@eigr/spawn-sdk'
import { UserState, ChangeUserNamePayload, ChangeUserNameResponse, ChangeUserNameStatus } from 'src/protos/examples/user_example'

const system = spawn.createSystem()

// You can register multiple actors with different options
const actor = system.buildActor({
  name: 'namedActorExample',
  stateType: UserState,
  kind: Kind.NAMED,
  stateful: true,
  snapshotTimeout: 10_000n,
  deactivatedTimeout: 60_000n
})

// This can be defined in a separate file
const setNameHandler = async (context: ActorContext<UserState>, payload: ChangeUserNamePayload) => {
  return Value.of<UserState, ChangeUserNameResponse>()
    .state({ name: payload.newName })
    .response({ status: ChangeUserNameStatus.OK })
}

// This is similar to a Route definition in REST
actor.addAction({ name: 'setName', payloadType: ChangeUserNamePayload, responseType: ChangeUserNameResponse }, setNameHandler)

system.register()
  .then(() => console.log('Spawn System registered'))
```

## Unnamed Actor

We can also create Unnamed Dynamic/Lazy actors, that is, despite having its behavior defined at compile time, a Lazy actor will only have a concrete instance when it is associated with an identifier/name at runtime. Below follows the same previous actor being defined as Unnamed.

```TS
import spawn, { ActorContext, Kind, Value } from '@eigr/spawn-sdk'
import { UserState, ChangeUserNamePayload, ChangeUserNameResponse, ChangeUserNameStatus } from 'src/protos/examples/user_example'

const system = spawn.createSystem()

const actor = system.buildActor({
  name: 'unnamedActorExample',
  stateType: UserState,
  kind: Kind.UNNAMED,
  stateful: true,
  snapshotTimeout: 10_000n,
  deactivatedTimeout: 60_000n
})

const setNameHandler = async (context: ActorContext<UserState>, payload: ChangeUserNamePayload) => {
  return Value.of<UserState, ChangeUserNameResponse>()
    .state({ name: payload.newName })
    .response({ status: ChangeUserNameStatus.OK })
}

actor.addAction({ name: 'setName', payloadType: ChangeUserNamePayload, responseType: ChangeUserNameResponse }, setNameHandler)

system.register()
  .then(() => console.log('Spawn System registered'))
```

## Pooled Actor

Sometimes we want a particular actor to be able to serve requests concurrently, however actors will always serve one request at a time using buffering mechanisms to receive requests in their mailbox and serve each request one by one. So to get around this behaviour you can configure your Actor as a Pooled Actor, this way the system will generate a pool of actors to meet certain requests. See an example below:

```TS
import spawn, { ActorContext, Kind, Value, Noop } from '@eigr/spawn-sdk'

const system = spawn.createSystem()

const actor = system.buildActor({
  name: 'pooledActorExample',
  kind: Kind.POOLED,
  minPoolSize: 1,
  maxPoolSize: 5
})

const somethingHandler = async (context: ActorContext<Noop>, payload: SomethingActionPayload) => {
  // you could do anything here with input
  // payload = something

  return Value.of<any, SomethingActionResponse>()
    .response({ something: true })
}

actor.addAction({ name: 'handleSomething', payloadType: SomethingActionPayload, responseType: SomethingActionResponse }, somethingHandler)

system.register()
  .then(() => console.log('Spawn System registered'))
```

## Default Actions

Actors also have some standard actions that are not implemented by the user and that can be used as a way to get the state of an actor without the invocation requiring an extra trip to the host functions. You can think of them as a cache of their state, every time you invoke a default action on an actor it will return the value directly from the Sidecar process without this target process needing to invoke its equivalent host function.

Let's take an example. Suppose Actor Joe wants to know the current state of Actor Robert. What Joe can do is invoke Actor Robert's default action called get_state. This will make Actor Joe's sidecar find Actor Robert's sidecar somewhere in the cluster and Actor Robert's sidecar will return its own state directly to Joe without having to resort to your host function, this in turn will save you a called over the network and therefore this type of invocation is faster than invocations of user-defined actions usually are.

Any invocations to actions with the following names will follow this rule: "get", "Get", "get_state", "getState", "GetState"

> **_NOTE_**: You can override this behavior by defining your actor as an action with the same name as the default actions. In this case it will be the Action defined by you that will be called, implying perhaps another network roundtrip



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