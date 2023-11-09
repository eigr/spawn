# Actor Host Resource
TODO

## Basic CRD Example:

```yaml
---
apiVersion: spawn-eigr.io/v1
kind: ActorHost
metadata:
  name: my-app 
  namespace: default
  annotations:
    spawn-eigr.io/actor-system: spawn-system
spec:
  host:
    image: eigr/my-app:latest 
```

## CRD Attributes

| CRD Attribute                                                            | Description     | Mandatory  | Default Value         | Possible Values |
| ------------------------------------------------------------------------ | --------------- | -----------| --------------------- | --------------- |
| .metadata.name                                                           |                 | Yes        |                       |                 |
| .metadata.namespace                                                      |                 | No         | default               |                 |
| .metadata.annotations.spawn-eigr.io/actor-system                         |                 | Yes        | spawn-system          |                 |
| .metadata.annotations.spawn-eigr.io/app-host                             |                 | No         | 0.0.0.0               |                 |
| .metadata.annotations.spawn-eigr.io/app-port                             |                 | No         | 8090                  |                 |
| .metadata.annotations.spawn-eigr.io/sidecar-address                      |                 | No         | 0.0.0.0               |                 |
| .metadata.annotations.spawn-eigr.io/sidecar-http-port                    |                 | No         | 9001                  |                 |
| .metadata.annotations.spawn-eigr.io/sidecar-http-pool-count              |                 | No         | 8                     |                 |
| .metadata.annotations.spawn-eigr.io/sidecar-http-pool-size               |                 | No         | 30                    |                 |
| .metadata.annotations.spawn-eigr.io/sidecar-http-pool-max-idle-timeout   |                 | No         | 1000                  |                 |
| .metadata.annotations.spawn-eigr.io/sidecar-delayed-invokes              |                 | No         | true                  |                 |
| .metadata.annotations.spawn-eigr.io/sidecar-crdt-sync-interval           |                 | No         | 2                     |                 |
| .metadata.annotations.spawn-eigr.io/sidecar-crdt-ship-interval           |                 | No         | 2                     |                 |
| .metadata.annotations.spawn-eigr.io/sidecar-crdt-ship-debounce           |                 | No         | 2                     |                 |
| .metadata.annotations.spawn-eigr.io/sidecar-state-handoff-sync-interval  |                 | No         | 60                    |                 |
| .metadata.annotations.spawn-eigr.io/supervisors-state-handoff-controller |                 | No         | persistent            |                 |
| .metadata.annotations.spawn-eigr.io/sidecar-mode                         |                 | No         | sidecar               | sidecar, daemon |
| .metadata.annotations.spawn-eigr.io/sidecar-image-tag                    |                 | No         | latest                |                 |
| .metadata.annotations.spawn-eigr.io/sidecar-uds-enabled                  |                 | No         | false                 |                 |
| .metadata.annotations.spawn-eigr.io/sidecar-uds-socket-path              |                 | No         | /var/run/spawn.sock   |                 |
| .metadata.annotations.spawn-eigr.io/sidecar-metrics-disabled             |                 | No         | false                 |                 |
| .metadata.annotations.spawn-eigr.io/sidecar-metrics-port                 |                 | No         | 9001                  |                 |
| .metadata.annotations.spawn-eigr.io/sidecar-metrics-log-console          |                 | No         | true                  |                 |
| .metadata.annotations.spawn-eigr.io/sidecar-pubsub-adapter               |                 | No         | native                |                 |
| .metadata.annotations.spawn-eigr.io/sidecar-pubsub-nats-hosts            |                 | No         | nats://127.0.0.1:4222 |                 |
| .metadata.annotations.spawn-eigr.io/cluster-poling-interval              |                 | No         | 3000                  |                 |
| .spec.replicas                                                           |                 | No         | 1                     |                 |
| .spec.volumes                                                            |                 | No         |                       |                 |
| .spec.terminationGracePeriodSeconds                                      |                 | No         | 405                   |                 |
| .spec.host.image                                                         |                 | Yes        |                       |                 |
| .spec.host.embedded                                                      |                 | No         | false                 |                 |
| .spec.host.ports                                                         |                 | No         |                       |                 |
| .spec.host.env                                                           |                 | No         |                       |                 |
| .spec.host.resources                                                     |                 | No         |                       |                 |
| .spec.host.antiAffinity                                                  |                 | No         |                       |                 |
| .spec.host.volumeMounts                                                  |                 | No         |                       |                 |



[Next: Activator Resource](crds/activator.md)

[Previous: Actor System Resource](crds/actor_system.md)