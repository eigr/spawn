# Actor System Resource
TODO

## Basic CRD Example:

```yaml
---
apiVersion: spawn-eigr.io/v1
kind: ActorSystem
metadata:
  name: spawn-system 
  namespace: default 
spec:
  statestore:
    type: MariaDB
    credentialsSecretRef: mariadb-connection-secret
    pool: 
      size: "10" 
```

## CRD Attributes

| CRD Attribute                                                            | Description     | Mandatory  | Default Value         | Possible Values |
| ------------------------------------------------------------------------ | --------------- | -----------| --------------------- | --------------- |
| .metadata.name                                                           |                 | Yes        |                       |                 |

[Next: Actor Host Resource](actor_host.md)

[Previous: Custom Resources](../crds.md)