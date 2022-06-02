# Spawn

**Actor Mesh Framework**

## Overview

Spawn is based on the sidecar proxy pattern to provide a multi-language Actor Model framework.
Spawn's technology stack on top of BEAM VM (Erlang's virtual machine) provides support for different languages from its native Actor model.

Spawn is made up of the following components:

* A semantic protocol based on Protocol Buffers
* A Sidecar Proxy written in Elixir that implements this protocol and persistent storage adapters.
* Support libraries in different programming languages.

## The Actor Model

TODO

## The Sidecar Pattern

TODO

## Spawn Architecture

TODO

## The Protocol

TODO

## SDKs

TODO

## Development

Run:

```shell
PROXY_DATABASE_TYPE=mysql SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= iex --name spawn_a2@127.0.0.1 -S mix
```