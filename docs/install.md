# Install

The recommended way to install Spawn is via our CLI tool.

### Prerequisites

- Kubernetes Cluster
- Nats broker accessible within the cluster.

### Instructions

Installing is very simple. First download and install our CLI in one command line:

```sh
curl -sSL https://github.com/eigr/spawn/releases/download/v2.0.0-RC5/install.sh | sh
```

At this point you will be ready to also install our Kubernetes Operator.

Assuming the Kubernetes context you want to install to is called `minikube` the command would be as follows:

```sh
spawn install k8s --context=minikube
```

See the demonstration below for a better understanding of the installation process:

![Setting Up Operator](gifs/install.gif)

> **_NOTE:_** For the full list of options use: `spawn install k8s --help`.

Alternatively, you can also install the Operator directly via the manifest file. The following command shows how this could be done directly via the command line:

```shell
kubectl create ns eigr-functions && curl -L https://github.com/eigr/spawn/releases/download/{release-version}/manifest.yaml | kubectl apply -f -
```

> **_NOTE:_** You need to inform the desired release version. For example:

```shell
kubectl create ns eigr-functions && curl -L https://github.com/eigr/spawn/releases/download/v2.0.0-RC5/manifest.yaml | kubectl apply -f -
```

[Back to Index](index.md)

[Next: Custom Resources](crds.md)

[Previous: Operator Manual](operator_manual.md)