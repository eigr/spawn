# Getting Started

First we must develop our HostFunction. Look for the documentation for each [SDK](sdks.md) to know how to proceed but below are some examples:

- [Using Elixir SDK](./spawn_sdk/spawn_sdk#installation)
- [Using Java SDK](https://github.com/eigr/spawn-java-std-sdk#getting-started)
- [Using NodeJS SDK](https://github.com/eigr/spawn-node-sdk#installation)
- [Using Python SDK](https://github.com/eigr/spawn-python-sdk#getting-started)

Having our container created and containing our Actor Host Function (following above SDK recommendations), we must deploy
it in a Kubernetes cluster with the Spawn Controller installed (See more about this
process in the section on installation).

In this tutorial we are going to use a MySql database. In this case, in order for Spawn to know how to connect to the database instance, it is first necessary to create a kubernetes secret in same namespace you installed the Spawn Operator with the connection data and other parameters. Example:

```shell
kubectl create secret generic mysql-connection-secret -n eigr-functions \
  --from-literal=database=eigr-functions-db \
  --from-literal=host='mysql' \
  --from-literal=port='3306' \
  --from-literal=username='admin' \
  --from-literal=password='admin' \
  --from-literal=encryptionKey=$(openssl rand -base64 32)
```

Sapwn securely encrypts the Actors' State, so the **_encryptionKey_** item must be informed and must be a key of reasonable size and complexity to ensure the security of your data.

> **_NOTE:_** To learn more about Statestores settings, see the [statestore section](statestores.md).

If you are going to use the Activators resource in your project or if you want your Actors to be able to communicate between different ActorSystems then you will need to create a secret with the connection information with the Nats server. See an example of how to do this below:

> **_NOTICE:_** It is not within the scope of this tutorial to install Nats but a simple way to do it in kubernetes is in to run these commands: **helm repo add nats https://nats-io.github.io/k8s/helm/charts/ && helm install spawn-nats nats/nats**.

Now create the config file with the Nats credentials:

```
kubectl -n default create secret generic nats-invocation-conn-secret \
  --from-literal=url="nats://spawn-nats:4222" \
  --from-literal=authEnabled="false" \
  --from-literal=tlsEnabled="false" \
  --from-literal=username="" \
  --from-literal=password=""
```

Now in a directory of your choice, create a file called **_system.yaml_** with the following content:

```yaml
---
apiVersion: spawn-eigr.io/v1
kind: ActorSystem
metadata:
  name: spawn-system # Mandatory. Name of the ActorSystem
  namespace: default # Optional. Default namespace is "default"
spec:
  # This externalInvocation section is necessary only if Nats broker is used in your project.
  externalInvocation:
    enabled: "true"
    externalConnectorRef: nats-invocation-conn-secret
  statestore:
    type: MySql # Valid are [MySql, Postgres, Sqlite, MSSQL, CockroachDB]
    credentialsSecretRef: mysql-connection-secret # The secret containing connection params created in the previous step.
    pool: # Optional
      size: "10"
```

This file will be responsible for creating a system of actors in the cluster.

Now create a new file called **_host.yaml_** with the following content:

```yaml
---
apiVersion: spawn-eigr.io/v1
kind: ActorHost
metadata:
  name: spawn-springboot-example # Mandatory. Name of the Node containing Actor Host Functions
  namespace: default # Optional. Default namespace is "default"
  annotations:
    # Mandatory. Name of the ActorSystem declared in ActorSystem CRD
    spawn-eigr.io/actor-system: spawn-system
spec:
  host:
    image: eigr/spawn-springboot-examples:latest # Mandatory
    ports:
      - name: "http"
        containerPort: 8091
```

This file will be responsible for deploying your host function and actors in the cluster.
But if you are using the SDK for Elixir then your Yaml should look like this:

```yaml
---
apiVersion: spawn-eigr.io/v1
kind: ActorHost
metadata:
  name: spawn-dice-game
  namespace: default
  annotations:
    spawn-eigr.io/actor-system: game-system
spec:
  host:
    embedded: true # This indicates that it is a native BEAM application and therefore does not need a sidecar proxy attached.
    image: eigr/dice-game-example:1.0.0-rc.22
    ports:
      - name: "http"
        containerPort: 8800
```

Now that the files have been defined, we can apply them to the cluster:

```shell
kubectl apply -f system.yaml
kubectl apply -f host.yaml
```

After that, just check your actors with:

```shell
kubectl get actorhosts
```

### Examples

Once you have done the initial setup you can start developing your actors in several available languages. See below how easy it is to do this:

<details open>
  <summary>JS</summary>

  ```js
  import spawn, { ActorContext, Value } from '@eigr/spawn-sdk'
  import { UserState, ChangeUserNamePayload, ChangeUserNameStatus } from 'src/protos/examples/user_example'

  const system = spawn.createSystem('SpawnSystemName')

  const actor = system.buildActor({
    name: 'joe',
    stateType: UserState, // or 'json' if you don't want to use protobufs
    stateful: true,
  })

  const setNameHandler = async (context: ActorContext<UserState>, payload: ChangeUserNamePayload) => {
    return Value.of<UserState, ChangeUserNameResponse>()
      .state({ name: payload.newName })
      .response(ChangeUserNameResponse, { status: ChangeUserNameStatus.OK })
  }

  actor.addAction({ name: 'setName', payloadType: ChangeUserNamePayload }, setNameHandler)
  ```
</details>

<details>
  <summary>Elixir</summary>
  
  ```elixir
  defmodule SpawnSdkExample.Actors.MyActor do
    use SpawnSdk.Actor,
      name: "joe",
      kind: :named,
      stateful: true, 
      state_type: Io.Eigr.Spawn.Example.MyState, # or :json if you don't care about protobuf types
    
    require Logger
    alias Io.Eigr.Spawn.Example.{MyState, MyBusinessMessage}

    defact sum(%MyBusinessMessage{value: value} = data, %Context{state: state} = ctx) do
      Logger.info("Received Request: #{inspect(data)}. Context: #{inspect(ctx)}")
      new_value = if is_nil(state), do: value, else: (state.value || 0) + value

      Value.of(%MyBusinessMessage{value: new_value}, %MyState{value: new_value})
    end
  end
  ```
</details>

<details>
  <summary>Java</summary>
  
  ```java
  package io.eigr.spawn.java.demo;

  import io.eigr.spawn.api.actors.Value;
  import io.eigr.spawn.api.actors.ActorContext;
  import io.eigr.spawn.api.actors.annotations.Action;
  import io.eigr.spawn.api.actors.annotations.stateful.StatefulNamedActor;
  import io.eigr.spawn.java.demo.domain.Domain;
  import org.slf4j.Logger;
  import org.slf4j.LoggerFactory;

  @StatefulNamedActor(name = "joe", stateType = Domain.JoeState.class)
  public class Joe {
    private static final Logger log = LoggerFactory.getLogger(Joe.class);

    @Action
    public Value setLanguage(Domain.Request msg, ActorContext<Domain.JoeState> context) {
        log.info("Received invocation. Message: {}. Context: {}", msg, context);
        if (context.getState().isPresent()) {
          log.info("State is present and value is {}", context.getState().get());
        }

        return Value.at()
                .response(Domain.Reply.newBuilder()
                        .setResponse("Hello From Java")
                        .build())
                .state(updateState("erlang"))
                .reply();
    }

    private Domain.JoeState updateState(String language) {
        return Domain.JoeState.newBuilder()
                .addLanguages(language)
                .build();
    }
  }
  ```
</details>

<details>
  <summary>Python</summary>
  
  ```python
  from domain.domain_pb2 import JoeState, Request
  from spawn.eigr.functions.actors.api.actor import Actor
  from spawn.eigr.functions.actors.api.settings import ActorSettings
  from spawn.eigr.functions.actors.api.context import Context
  from spawn.eigr.functions.actors.api.value import Value

  actor = Actor(settings=ActorSettings(
      name="joe", stateful=True, channel="test"))


  @actor.action("setLanguage")
  def set_language(request: Request, ctx: Context) -> Value:
      new_state = None

      if not ctx.state:
          new_state = JoeState()
          new_state.languages.append("python")
      else:
          new_state = ctx.state

      return Value().state(new_state).noreply()
  ```
</details>

<details>
  <summary>Rust</summary>
  
  ```rust
  use spawn_examples::domain::domain::{Reply, Request, State};
  use spawn_rs::{value::Value, Context, Message};

  use log::info;

  pub fn set_language(msg: Message, ctx: Context) -> Value {
      info!("Actor msg: {:?}", msg);
      return match msg.body::<Request>() {
          Ok(request) => {
              let lang = request.language;
              info!("Setlanguage To: {:?}", lang);
              let mut reply = Reply::default();
              reply.response = lang;

              match &ctx.state::<State>() {
                  Some(state) => Value::new()
                      .state::<State>(&state.as_ref().unwrap(), "domain.State".to_string())
                      .response(&reply, "domain.Reply".to_string())
                      .to_owned(),
                  _ => Value::new()
                      .state::<State>(&State::default(), "domain.State".to_string())
                      .response(&reply, "domain.Reply".to_string())
                      .to_owned(),
              }
          }
          Err(_e) => Value::new()
              .state::<State>(&State::default(), "domain.State".to_string())
              .to_owned(),
      };
  }
  ```
</details>

You can find some project examples of using Spawn in the links below:

- **Hatch**: https://github.com/zblanco/hatch
- **Elixir Dice Game. Spawn with Phoenix app**: https://github.com/eigr-labs/spawn_game_example.git
- **Distributed Image Processing**: https://github.com/eigr-labs/spawn-distributed-image-processing
- **Federated Data Example**: https://github.com/eigr-labs/spawn-federated-data-example
- **Fleet**: https://github.com/sleipnir/fleet-spawn-example
- **Postal Code Search**: https://github.com/h3nrique/postalcode-spawn-demo
- **Spawn Polyglot Example**: https://github.com/sleipnir/spawn-polyglot-ping-pong

But in the next section you will be taken to the correct link for each supported SDK.

> **_NOTICE:_** Not all samples may be up to date with the latest version of Spawn and SDKs.

[Next: SDKs](sdks.md)

[Previous: Install](install.md)