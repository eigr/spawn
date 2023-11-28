# Install

The recommended way to install Spawn is via our Kubernetes Operator.

### Prerequisites

- Kubernetes Cluster
- Nats broker accessible within the cluster (See the note below).

> **_Important:_** Nats broker is only necessary if you want to use the Activators feature or if you need your actors to communicate between different ActorSystems.

### Instructions

To install you need to download the Operator manifest file. The following command shows how this could be done directly via the command line:

```shell
kubectl create ns eigr-functions && curl -L https://github.com/eigr/spawn/releases/download/{release-version}/manifest.yaml | kubectl apply -f -
```

> **_NOTE:_** You need to inform the desired release version. For example:

```shell
kubectl create ns eigr-functions && curl -L https://github.com/eigr/spawn/releases/download/v1.0.0-rc.35/manifest.yaml | kubectl apply -f -
```

[Next: Getting Started](getting_started.md)

[Previous: Features](features.md)