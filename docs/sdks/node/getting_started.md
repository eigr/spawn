# Node Getting Started

First install CLI:

```SH
curl -sSL https://github.com/eigr/spawn/releases/download/v2.0.0-RC2/install.sh | sh
```

_We recommend you to use Typescript for better usage overall._

This lib supports both Bun and NodeJS runtimes, Bun performs invocations ~2x faster, we recommend using Bun.

### Create a new project with

```SH
spawn new node hello_world
```

### Run the new project with your preferred package manager

```SH
# with yarn
yarn start

# or with pnpm
pnpm start

# or if you want to use bun instead of NodeJS use:
yarn start-bun
```

### Run the Spawn Proxy using the CLI for dev purposes

```SH
spawn dev run -p ./protos -s spawn-system -W
```

### Invoking the actor

Thats it! You can test invoking the hello world actor with our pre configured HTTP activator.

```SH
curl -vvv -H 'Accept: application/json' http://localhost:9980/v1/hello_world?message=World
```

[Next: Actors](actors.md)

[Previous: SDKs](../../sdks.md)