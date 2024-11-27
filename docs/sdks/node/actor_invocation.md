# Actor Invocation

You can invoke actor functions defining:

```TS
import spawn, { payloadFor } from '@eigr/spawn-sdk'

/**
 * InvokeOpts fields:
 * - action - The action to be executed
 * - system - (optional, defaults to current registered system) The system that the actor belongs to
 * - response - (optional) The expected response type
 * - payload - (optional) The payload to be passed to the action
 * - async - (optional) Whether the action should be executed asynchronously
 * - pooled - (optional) Whether the action should be executed in a pooled actor
 * - metadata - (optional) Additional metadata to be passed to the action
 * - ref - (optional) A reference to the named actor if you want to also spawn it during invocation, not needing to call spawnActor previously
 * - scheduledTo - (optional) The scheduled date to be executed
 * - delay - (optional) The delay in ms this will be invoked
 */
spawn.invoke('pooledActorExample', {
  action: 'handleSomething', // The action to be executed
  system: 'systemName', // (optional, defaults to current registered system) The system that the actor belongs to
  async: true, // you dont care about the response
  pooled: true, // you are invoking in a Kind.POOLED actor
  ref: "registeredActorName", // you are invoking a Kind.NAMED actor and spawning a instance based on the ActorName of the first arg
  scheduledTo: new Date(new Date().setMinutes(new Date().getMinutes() + 10)), // you are delaying this invoke to 10 minutes
  delay: 10_000, // you are delaying this to 10s in the future
  payload: payloadFor(SomethingActionPayload, { something: 'Something you will be using inside handler' }),
  response: SomethingActionResponse // if you care about the response you have to infer its type to the invoke
})
.then(response => console.log(response))
```

## Named Actor

It can be invoked with:

```TS
import spawn, { payloadFor } from '@eigr/spawn-sdk'
import { ChangeUserNamePayload, ChangeUserNameResponse } from 'src/protos/examples/user_example'

spawn.invoke('unnamedActorExample', {
  action: 'setName',
  response: ChangeUserNameResponse,
  payload: payloadFor(ChangeUserNamePayload, { newName: 'newName for actor' })
})
.then(response => console.log(response)) // { status: 1 }
```

## Unnamed Actor

It can be invoked with:

```TS
import spawn, { payloadFor } from '@eigr/spawn-sdk'
import { ChangeUserNamePayload, ChangeUserNameResponse } from 'src/protos/examples/user_example'

spawn.invoke('some-user-id-01', {
  action: 'setName',
  ref: 'unnamedActorExample',
  response: ChangeUserNameResponse,
  payload: payloadFor(ChangeUserNamePayload, { newName: 'newName for actor some-user-id-01' })
})
.then(response => console.log(response)) // { status: 1 }
```

Notice that the only thing that has changed is the the kind of actor, in this case the kind is set to `Kind.UNNAMED`
And we need to reference the original name in the invocation or instantiate it before using `spawn.spawnActor`

## Pooled Actor

```TS
import spawn, { payloadFor } from '@eigr/spawn-sdk'

spawn.invoke('pooledActorExample', {
  action: 'handleSomething',
  pooled: true,
  payload: payloadFor(SomethingActionPayload, { something: 'Something you will be using inside handler' })
})
.then(response => console.log(response))
```

[Next: Workflows](workflows.md)

[Previous: Actors](actors.md)