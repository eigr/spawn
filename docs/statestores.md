# Statestores

Statestores are the interface between the downstream storage/database system and the actor.
They are configured by the user via environment variables or by the ActorSystem CRD (see [Custom Resources section](crds.md)) and their sensitive data is [stored in kubernetes secrets](docs/getting_started.md).

Below is a list of common global settings for all Statestores. These variables are automatically configured by our Kubernetes Operator Controller, but you can use them to configure your application for local development.

| Environment Variable        | CRD Attribute                        | Secret Property | Default Env Value | Default CRD Value | Mandatory | Possible Values                         |
| --------------------------- | ------------------------------------ | --------------- | ----------------- | ----------------- | --------- | --------------------------------------- |
|                             | spec.statestore.credentialsSecretRef |                 |                   |                   | Yes       |
| PROXY_DATABASE_TYPE         | spec.statestore.type                 |                 |                   |                   | Yes       | 
| PROXY_DATABASE_NAME         |                                      | database        | eigr-functions-db | eigr-functions-db |           |
| PROXY_DATABASE_USERNAME     |                                      | username        | admin             | admin             |           |
| PROXY_DATABASE_SECRET       |                                      | password        | admin             | admin             |           |
| PROXY_DATABASE_HOST         |                                      | host            | localhost         | localhost         |           |
| PROXY_DATABASE_PORT         |                                      | port            | adapter specific  | adapter specific  |           | 
| SPAWN_STATESTORE_KEY        |                                      | encryptionKey   |                   |                   | Yes       | openssl rand -base64 32                 |
| PROXY_DATABASE_POOL_SIZE    | spec.statestore.pool.size            |                 | 60                | 60                |           |
| PROXY_DATABASE_QUEUE_TARGET | spec.statestore.pool.queue           |                 | 10000             | 10000             |           |
| PROXY_DATABASE_SSL          | spec.statestore.ssl                  |                 | false             | false             |           |
| PROXY_DATABASE_SSL_VERIFY   | spec.statestore.ssl_verify           |                 | false             | false             |           |

> **_NOTE:_** When running on top of Kubernetes you only need to set the CRD attributes of ActorSystem and Kubernetes secrets. The Operator will set the values of the environment variables according to the settings of these two mentioned places.

### Actor State Checkpoints Restore

Spawn provides the ability to start Actors from a certain point in time.
For this we use the concept of revision.
A review happens whenever a state change is detected by the actor and a recording of the new state is made during a snapshot event. Each time this occurs an increment in the revision number will occur marking the state to that moment in time.
Developers can therefore start any Actor from a specific point in time which is marked by a revision.
How developers will do this will depend on the APIs exposed by the SDK's for each specific language, so to learn more about this feature, check the desired SDK page.

It is also worth mentioning that this feature depends on the implementation of each of our persistent storage adapters, so check the table in the section below to find out if the adapter for your database supports this feature.

### Statestore Features

| Feature                                   | CockroachDB | MariaDB | Mnesia | MSSQL | MySQL | Postgres | SQLite |
| ------------------------------------------| ------------| --------| -------| ------| ------| ---------| -------|
| Actor Fast key lookup                     |     [x]     |   [x]   |   [ ]  |  [x]  |  [x]  |   [x]    |   [x]  |
| Actor State restore from Revision         |     [ ]     |   [x]   |   [ ]  |  [ ]  |  [ ]  |   [ ]    |   [ ]  |
| Search by Actors Metadata                 |     [ ]     |   [ ]   |   [ ]  |  [ ]  |  [ ]  |   [ ]    |   [ ]  |
| Search by all changes of Actor states     |     [ ]     |   [x]   |   [ ]  |  [ ]  |  [ ]  |   [ ]    |   [ ]  |
| Search by all Actor state changes by date |     [ ]     |   [x]   |   [ ]  |  [ ]  |  [ ]  |   [ ]    |   [ ]  |
| Snapshot Data Partition                   |     [ ]     |   [x]   |   [ ]  |  [ ]  |  [ ]  |   [ ]    |   [ ]  |
| State AES Encryption                      |     [x]     |   [x]   |   [ ]  |  [x]  |  [x]  |   [x]    |   [x]  |


[Next: Activators](activators.md)

[Previous: Custom Resources](crds.md)