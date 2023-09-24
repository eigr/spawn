# Getting Started

## Getting Started

First we must develop our HostFunction. Look for the documentation for [each SDK](sdks.md) to know how to proceed but below are some examples:

- [Using Elixir SDK](./spawn_sdk/spawn_sdk#installation)
- [Using Java SDK](https://github.com/eigr/spawn-springboot-sdk/blob/main/README.md#installation)
- [Using NodeJS SDK](https://github.com/eigr/spawn-node-sdk#installation)

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
    image: eigr/dice-game-example:1.0.0-rc.18
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

You can find some examples of using Spawn in the links below:

- **Hatch**: https://github.com/zblanco/hatch
- **Elixir Dice Game. Spawn with Phoenix app**: https://github.com/eigr-labs/spawn_game_example.git
- **Distributed Image Processing**: https://github.com/eigr-labs/spawn-distributed-image-processing
- **Federated Data Example**: https://github.com/eigr-labs/spawn-federated-data-example
- **Fleet**: https://github.com/sleipnir/fleet-spawn-example
- **Spawn Polyglot Example**: https://github.com/sleipnir/spawn-polyglot-ping-pong

[Previous: Install](install.md) 

[Next: SDKs](sdks.md)