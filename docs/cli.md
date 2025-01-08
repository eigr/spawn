# Spawn CLI Documentation

The Spawn CLI is a powerful command-line tool designed to simplify the management and development of Spawn projects and infrastructure. This guide provides an overview of the available commands, their subcommands, and usage examples.

---

## Commands Overview

* `new`: Create new Spawn projects targeting a specific programming language.

* `apply`: Deploy actor resources to a Kubernetes cluster.

* `config`: Configure Spawn applications, such as ActorSystem and ActorHost CRDs.

* `dev`: Manage local development workflows.

* `install`: Install orchestrators or runtimes, such as Kubernetes.

* `playground`: Set up and run a complete Spawn tutorial.

Each command comes with its own set of options and subcommands, which are detailed below.

---

### 1. `new` Command

#### **Description:**
Creates a new Spawn project tailored for a specific target language.

#### **Usage:**

```bash
spawn new <subcommand> [OPTIONS] <name>
```

#### **Subcommands:**

* `dart`: Generate a Spawn Dart project.

#### **Options for** `new dart`:

* - `--help`: Print this help.

* - `-s`, `--actor-system`: Defines the name of the ActorSystem. (Default: "spawn-system")

* - `-d`, `--app-description`: Defines the application description. (Default: "Spawn App.")

* - `-t`, `--app-image-tag`: Defines the OCI Container image tag. (Default: 
"ttl.sh/spawn-dart-example:1h")

* - `-n`, `--app-namespace`: Defines the Kubernetes namespace to install app. (Default: "default")

* - `-v`, `--sdk-version`: Spawn SDK version.

* - `-S`, `--statestore-type`: Spawn statestore provider. (Allowed Values: "cockroachdb", "mariadb", "mssql", "mysql", "postgres", "sqlite")

* - `-U`, `--statestore-user`: Spawn statestore username. (Default: "admin")

* - `-P`, `--statestore-pwd`: Spawn statestore password. (Default: "admin")

* - `-K`, `--statestore-key`: Spawn statestore key. (Default: "myfake-key")

#### **Example:**

```bash
spawn new dart --actor-system=spawn-system myapp
```
---

* `elixir`: Generate a Spawn Elixir project.

#### **Options for** `new elixir`:

* - `--help`: Print this help.

* - `-s`, `--actor-system`: Defines the name of the ActorSystem. (Default: "spawn-system")

* - `-d`, `--app-description`: Defines the application description. (Default: "Spawn App.")

* - `-t`, `--app-image-tag`: Defines the OCI Container image tag. (Default: 
"ttl.sh/spawn-elixir-example:1h")

* - `-n`, `--app-namespace`: Defines the Kubernetes namespace to install app. (Default: "default")

* - `-e`, `--elixir-version`: Defines the Elixir version.

* - `-v`, `--sdk-version`: Spawn SDK version.

* - `-S`, `--statestore-type`: Spawn statestore provider. (Allowed Values: "cockroachdb", "mariadb", "mssql", "mysql", "postgres", "sqlite")

* - `-U`, `--statestore-user`: Spawn statestore username. (Default: "admin")

* - `-P`, `--statestore-pwd`: Spawn statestore password. (Default: "admin")

* - `-K`, `--statestore-key`: Spawn statestore key. (Default: "myfake-key")

#### **Example:**

```bash
spawn new elixir --actor-system=spawn-system --statestore-type=postgres myapp
```
---

* `go`: Generate a Spawn Dart project.

#### **Options for** `new go`:

* - `--help`: Print this help.

* - `-s`, `--actor-system`: Defines the name of the ActorSystem. (Default: "spawn-system")

* - `-s`, `--actor-system`: Defines the name of the ActorSystem. (Default: "spawn-system")

* - `-d`, `--app-description`: Defines the application description. (Default: "Spawn App.")

* - `-t`, `--app-image-tag`: Defines the OCI Container image tag. (Default: 
"ttl.sh/spawn-go-example:1h")

* - `-n`, `--app-namespace`: Defines the Kubernetes namespace to install app. (Default: "default")

* - `-v`, `--sdk-version`: Spawn SDK version.

* - `-S`, `--statestore-type`: Spawn statestore provider. (Allowed Values: "cockroachdb", "mariadb", "mssql", "mysql", "postgres", "sqlite")

* - `-U`, `--statestore-user`: Spawn statestore username. (Default: "admin")

* - `-P`, `--statestore-pwd`: Spawn statestore password. (Default: "admin")

* - `-K`, `--statestore-key`: Spawn statestore key. (Default: "myfake-key")

#### **Example:**

```bash
spawn new go --actor-system=spawn-system myapp
```
---

* `java`: Generate a Spawn Java project.

#### **Options for** `new java`:

* - `--help`: Print this help.

* - `-s`, `--actor-system`: Defines the name of the ActorSystem. (Default: "spawn-system")

* - `-d`, `--app-description`: Defines the application description. (Default: "Spawn App.")

* - `-t`, `--app-image-tag`: Defines the OCI Container image tag. (Default: 
"ttl.sh/spawn-java-example:1h")

* - `-n`, `--app-namespace`: Defines the Kubernetes namespace to install app. (Default: "default")

* - `-v`, `--sdk-version`: Spawn SDK version.

* - `-S`, `--statestore-type`: Spawn statestore provider. (Allowed Values: "cockroachdb", "mariadb", "mssql", "mysql", "postgres", "sqlite")

* - `-U`, `--statestore-user`: Spawn statestore username. (Default: "admin")

* - `-P`, `--statestore-pwd`: Spawn statestore password. (Default: "admin")

* - `-K`, `--statestore-key`: Spawn statestore key. (Default: "myfake-key")

* - `-g`, `--group-id`: Java project groupId. (Default: "io.eigr.spawn.java")

* - `-a`, `--artifact-id`: Java project artifactId. (Default: "demo")

* - `-V`, `--version`: Java project version. (Default: "1.0.1")

#### **Example:**

```bash
spawn new java --actor-system=spawn-system myapp
```
---

* `node`: Generate a Spawn NodeJS project.

#### **Options for** `new node`:

* - `--help`: Print this help.

* - `-s`, `--actor-system`: Defines the name of the ActorSystem. (Default: "spawn-system")

* - `-d`, `--app-description`: Defines the application description. (Default: "Spawn App.")

* - `-t`, `--app-image-tag`: Defines the OCI Container image tag. (Default: 
"ttl.sh/spawn-node-example:1h")

* - `-n`, `--app-namespace`: Defines the Kubernetes namespace to install app. (Default: "default")

* - `-v`, `--sdk-version`: Spawn SDK version.

* - `-S`, `--statestore-type`: Spawn statestore provider. (Allowed Values: "cockroachdb", "mariadb", "mssql", "mysql", "postgres", "sqlite")

* - `-U`, `--statestore-user`: Spawn statestore username. (Default: "admin")

* - `-P`, `--statestore-pwd`: Spawn statestore password. (Default: "admin")

* - `-K`, `--statestore-key`: Spawn statestore key. (Default: "myfake-key")

#### **Example:**

```bash
spawn new node --actor-system=spawn-system myapp
```
---

* `python`: Generate a Spawn Python project.

#### **Options for** `new python`:

* - `--help`: Print this help.

* - `-s`, `--actor-system`: Defines the name of the ActorSystem. (Default: "spawn-system")

* - `-d`, `--app-description`: Defines the application description. (Default: "Spawn App.")

* - `-t`, `--app-image-tag`: Defines the OCI Container image tag. (Default: 
"ttl.sh/spawn-python-example:1h")

* - `-n`, `--app-namespace`: Defines the Kubernetes namespace to install app. (Default: "default")

* - `-v`, `--sdk-version`: Spawn SDK version.

* - `-S`, `--statestore-type`: Spawn statestore provider. (Allowed Values: "cockroachdb", "mariadb", "mssql", "mysql", "postgres", "sqlite")

* - `-U`, `--statestore-user`: Spawn statestore username. (Default: "admin")

* - `-P`, `--statestore-pwd`: Spawn statestore password. (Default: "admin")

* - `-K`, `--statestore-key`: Spawn statestore key. (Default: "myfake-key")

#### **Example:**

```bash
spawn new python --actor-system=spawn-system myapp
```
---

* `rust`: Generate a Spawn Rust project.

#### **Options for** `new rust`:

* - `--help`: Print this help.

* - `-s`, `--actor-system`: Defines the name of the ActorSystem. (Default: "spawn-system")

* - `-d`, `--app-description`: Defines the application description. (Default: "Spawn App.")

* - `-t`, `--app-image-tag`: Defines the OCI Container image tag. (Default: 
"ttl.sh/spawn-rust-example:1h")

* - `-n`, `--app-namespace`: Defines the Kubernetes namespace to install app. (Default: "default")

* - `-v`, `--sdk-version`: Spawn SDK version.

* - `-S`, `--statestore-type`: Spawn statestore provider. (Allowed Values: "cockroachdb", "mariadb", "mssql", "mysql", "postgres", "sqlite")

* - `-U`, `--statestore-user`: Spawn statestore username. (Default: "admin")

* - `-P`, `--statestore-pwd`: Spawn statestore password. (Default: "admin")

* - `-K`, `--statestore-key`: Spawn statestore key. (Default: "myfake-key")

#### **Example:**

```bash
spawn new rust --actor-system=spawn-system myapp
```
---

### 2. `apply` Command

#### **Description:**
Applies Spawn actor resources to a Kubernetes cluster.

#### **Usage:**

```bash
spawn apply [OPTIONS]
```

#### **Options:**

* - `-c`, `--context` <context>: Apply manifest on specified Kubernetes Context. (Default: "minikube")

* - `-f`, `--file` <path>: Specify the file containing actor resource definitions.

* - `-n`, `--namespace` <namespace>: Define the Kubernetes namespace for deployment.

* - `-d`, `--dry-run`: Preview the resources to be applied without making changes.

* - `-k`, `--kubeconfig`: Load a Kubernetes kube config file. (Default: "~/.kube/config")

#### **Example:**

```bash
spawn apply --file=myapp-actor-host.yaml
```
---

### 3. `config` Command

#### **Description:**
Configures Spawn applications, including ActorSystem and ActorHost CRDs.

#### **Usage:**

TODO

---

### 4. `dev` Command

#### **Description:**
Manages local development workflows.

#### **Usage:**

```bash
spawn dev <subcommand> [options]
```

#### **Subcommands:**

* `run`: Run Spawn proxy in dev mode.

#### **Options for** `dev run`:

* - `--help`: Print this help.

* - `-s`, `--actor-system`: "Defines the name of the ActorSystem.

* - `-p`, `--protos`: Path where your protobuf files reside.

* - `-W`, `--proto-changes-watcher`: Watches changes in protobuf files and reload proxy.

* - `-A`, `--proxy-bind-address`: Defines the proxy host address.

* - `-P`, `--proxy-bind-port`: Defines the proxy host port.

* - `-G`, `--proxy-bind-grpc-port`: Defines the proxy gRPC host port.

* - `-I`, `--proxy-image`: Defines the proxy image.

* - `-H`, `--actor-host-port`: Defines the ActorHost (your program) port.

* - `-S`, `--database-self-provisioning`: Auto provisioning a local Database.

* - `-h`, `--database-host`: Defines the Database hostname.

* - `-D`, `--database-port`: Defines the Database port number.

* - `-T`, `--database-type`: Defines the Database provider.

* - `O`, `--database-pool`: Defines the Database pool size.

* - `-K`, `--statestore-key`: Defines the Statestore Key.

* - `-L`, `--log-level`: Defines the Logger level."

* - `-N`, `--nats-image`: Nats test image

* - `--nats-http-port`: Nats http port"

* - `--nats-port`: Nats port

* - `-n`, `--name`: Defines the name of the Proxy instance.

#### **Example:**

```bash
spawn dev run --actor-system "custom-system" \
    --protos="./protos" \
    --proxy-bind-address="192.168.1.1" \
    --proxy-bind-port=8080 \
    --proxy-image="custom/proxy:latest" \
    --actor-host-port=9090 \
    --database-self-provisioning=false \
    --database-host="localhost" \
    --database-port 5432 \
    --database-type="postgres" \
    --database-pool=50  \
    --statestore-key="custom-key" \
    --log-level="debug" \
    --nats-image="nats" \
    --nats-http-port=8222 \
    --nats-port=4222 \
    --name="custom-proxy"
```
---

### 5. `install` Command

#### **Description:**
Installs orchestrators or runtimes, such as Kubernetes.

#### **Usage:**

```bash
spawn install <runtime> [options]
```

#### **Runtimes:**

* `kubernetes`: Install k8s Operator Runtime.

#### **Options for** `install kubernetes`:

* - `--help`: Print this help.

* - `-c`, `--context`: Apply manifest on specified Kubernetes Context.

* - `-e`, `--env-config`: Load a Kubernetes kube config from environment variable.

* - `-k`, `--kubeconfig`: Load a Kubernetes kube config file. (Default: "~/.kube/config")

* - `-V`, `--version`: Install Operator with a specific version.

#### **Example:**

```bash
spawn install --version=1.4.2
```
---

### 6. `playground` Command

#### **Description:**
Sets up and runs a complete Spawn tutorial, providing a self-contained learning environment.

#### **Usage:**

```bash
spawn playground <subcommand> [options]
```

#### **Subcommand:**

* `new`: Create and run a new Spawn playground.

#### **Options for** `playground new`:

* - `--help`: Print this help.

* - `-n`, `--name`: Defines the name of the Playground.

* - `-N`, `--namespace`: Apply manifests on specified Kubernetes namespace.

* - `-r`, `--recipe`: Playground recipe to install. See `spawnctl playground list` command.

* - `-t`, `--timeout`: Defines the timeout for execution of command.

* - `-k`, `--k8s-flavour`: Defines the kubernetes provider. (Allowed values: ["k3d", "kind", "minikube"])


#### **Example:**

```bash
spawn playground new --name=test
```
---

* `list`: List available recipes for playground.

#### **Options for** `playground list`:

TODO

#### **Example:**

```bash
spawn playground list 
```
---

[Back to Index](index.md)

[Next: Custom Resources](crds.md)

[Previous: Install](install.md)