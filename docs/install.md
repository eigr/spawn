# Install

The recommended way to install Spawn is via our Kubernetes Operator.

### Prerequisites

- Kubernetes Cluster
- Nats broker accessible within the cluster (See the note below).

> **_Important:_** Nats broker is only necessary if you want to use the Activators feature or if you need your actors to communicate between different ActorSystems.

### Instructions

Installing is very simple. First download and install our CLI in one command line:

```sh
curl -sSL https://github.com/eigr/spawn/releases/download/v1.4.3/install.sh | sh
```

At this point you will be ready to also install our Kubernetes Operator. Assuming the Kubernetes context you want to install to is called `minikube` the command would be as follows:

```sh
spawn install k8s --context=minikube
```

For the full list of options use spawn install kubernetes: `spawn install k8s --help`.

Alternatively you can also install the Operator directly via manifest file.. The following command shows how this could be done directly via the command line:

```shell
kubectl create ns eigr-functions && curl -L https://github.com/eigr/spawn/releases/download/{release-version}/manifest.yaml | kubectl apply -f -
```

> **_NOTE:_** You need to inform the desired release version. For example:

```shell
kubectl create ns eigr-functions && curl -L https://github.com/eigr/spawn/releases/download/v1.4.3/manifest.yaml | kubectl apply -f -
```

[Next: Getting Started](getting_started.md)

[Previous: Features](features.md)