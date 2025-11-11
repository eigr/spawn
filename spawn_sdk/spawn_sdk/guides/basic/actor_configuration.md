# Actor Configuration

This guide covers all the configuration options available when defining Spawn actors.

## Basic Configuration Options

### Actor Definition

```elixir
defmodule MyApp.Actors.ConfiguredActor do
  use SpawnSdk.Actor,
    name: "configured_actor",           # Actor name in the system
    kind: :named,                       # :named | :unnamed
    stateful: true,                     # true | false
    state_type: MyApp.Domain.MyState,   # Protobuf type or :json
    deactivate_timeout: 30_000,         # Milliseconds before deactivation
    snapshot_timeout: 2_000,            # Milliseconds between snapshots
    channels: [                         # Channels for broadcast messages
      {"my.channel", "handle_broadcast"}
    ]

  # Actor implementation...
end
```

## Configuration Parameters

### name
- **Type:** String
- **Default:** Module name (`__MODULE__`)
- **Description:** The unique identifier for this actor in the system

```elixir
# Using custom name
name: "my_custom_actor"

# Using module name (default)
# name defaults to "MyApp.Actors.ConfiguredActor"
```

### kind
- **Type:** `:named | :unnamed`
- **Default:** `:named`
- **Description:** Determines how the actor is instantiated

```elixir
# Named actor - created at system startup
kind: :named

# Unnamed actor - created dynamically
kind: :unnamed
```

### stateful
- **Type:** `true | false`
- **Default:** `true`
- **Description:** Whether the actor maintains state between invocations

```elixir
# Stateful actor - maintains state
stateful: true

# Stateless actor - no state persistence
stateful: false
```

### state_type
- **Type:** Module (Protobuf) | `:json`
- **Default:** None (required for stateful actors)
- **Description:** The type used for actor state serialization

```elixir
# Using Protobuf type
state_type: MyApp.Domain.UserState

# Using JSON (less efficient)
state_type: :json
```

### deactivate_timeout
- **Type:** Integer (milliseconds)
- **Default:** 30,000 (30 seconds)
- **Description:** Time of inactivity before actor is deactivated

```elixir
# 5 minutes
deactivate_timeout: 300_000

# Never deactivate (24 hours)
deactivate_timeout: 86_400_000

# Quick deactivation for testing
deactivate_timeout: 5_000
```

### snapshot_timeout
- **Type:** Integer (milliseconds)
- **Default:** 2,000 (2 seconds)
- **Description:** Interval for automatic state snapshots

```elixir
# Snapshot every 10 seconds
snapshot_timeout: 10_000

# Frequent snapshots for critical data
snapshot_timeout: 1_000

# Less frequent snapshots for performance
snapshot_timeout: 30_000
```

### channels
- **Type:** List of tuples `{channel_name, action_name}`
- **Default:** `[]`
- **Description:** Channels this actor subscribes to for broadcast messages

```elixir
# Subscribe to multiple channels
channels: [
  {"user.events", "handle_user_event"},
  {"system.notifications", "handle_notification"}
]

# Simple channel subscription (uses "receive" action)
channels: ["my.channel"]
```

## Action Configuration

### Basic Actions

```elixir
# Simple action
action "MyAction", fn ctx, payload ->
  # Action implementation
end

# Action with multiple clauses
action "ProcessMessage" do
  # Pattern matching on different message types
  fn ctx, %MyApp.Events.UserCreated{} = event ->
    # Handle user created
  end

  fn ctx, %MyApp.Events.UserDeleted{} = event ->
    # Handle user deleted
  end
end
```

### Timer Actions

```elixir
# Timer action - executes every 30 seconds
action "Heartbeat", [timer: 30_000], fn %Context{} = ctx ->
  Logger.info("Heartbeat from #{ctx.caller}")
  Value.of()
end

# Timer with immediate execution
action "Initialize", [timer: 60_000, immediate: true], fn ctx ->
  # Runs immediately when actor starts, then every minute
end
```

### Initialization Actions

Special action names that trigger during actor initialization:

```elixir
# Standard initialization actions
init fn ctx ->
  # Called when actor starts
end

# Alternative names (any of these work)
action "init", fn ctx -> ... end
action "Init", fn ctx -> ... end  
action "setup", fn ctx -> ... end
action "Setup", fn ctx -> ... end
```

## Environment Configuration

Spawn can be configured using environment variables for deployment compatibility:

### Database Configuration

```bash
# Database type
export PROXY_DATABASE_TYPE=postgres  # postgres | mysql

# State store encryption
export SPAWN_STATESTORE_KEY=your-encryption-key-here

# Function port
export USER_FUNCTION_PORT=8092
```

### Elixir Configuration

Alternatively, use traditional Elixir configuration:

```elixir
# config/config.exs
config :spawn,
  pubsub_group: :my_actor_channel  # Default: :actor_channel
```

## Performance Considerations

### For High-Traffic Actors

```elixir
use SpawnSdk.Actor,
  name: "high_traffic_actor",
  stateful: true,
  deactivate_timeout: 300_000,    # Longer timeout for active actors
  snapshot_timeout: 1_000         # More frequent snapshots
```

### For Memory-Sensitive Actors

```elixir
use SpawnSdk.Actor,
  name: "memory_sensitive_actor",
  stateful: true,
  deactivate_timeout: 10_000,     # Quick deactivation
  snapshot_timeout: 30_000        # Less frequent snapshots
```

### For Stateless Workers

```elixir
use SpawnSdk.Actor,
  name: "worker_actor",
  kind: :unnamed,
  stateful: false                 # No state = better performance
```

## Best Practices

### Naming Conventions

```elixir
# Use descriptive names
name: "user_session_manager"
name: "order_processor"
name: "payment_validator"

# For unnamed actors, use type names
name: "user_session"    # Instances: user_session_123, user_session_456
name: "shopping_cart"   # Instances: shopping_cart_abc, shopping_cart_xyz
```

### State Types

```elixir
# Prefer Protobuf for performance
state_type: MyApp.Domain.UserState

# Use JSON only for rapid prototyping
state_type: :json
```

### Timeout Configuration

```elixir
# For frequently accessed actors
deactivate_timeout: 600_000  # 10 minutes

# For occasionally accessed actors  
deactivate_timeout: 60_000   # 1 minute

# For cached data actors
deactivate_timeout: 1_800_000 # 30 minutes
```

## Common Patterns

### User Session Actor

```elixir
defmodule MyApp.Actors.UserSession do
  use SpawnSdk.Actor,
    name: "user_session",
    kind: :unnamed,
    state_type: MyApp.Domain.SessionState,
    deactivate_timeout: 1_800_000,  # 30 min session timeout
    snapshot_timeout: 10_000        # Save every 10 seconds
end
```

### System Service Actor

```elixir
defmodule MyApp.Actors.ConfigService do
  use SpawnSdk.Actor,
    name: "config_service",
    kind: :named,
    state_type: MyApp.Domain.ConfigState,
    deactivate_timeout: 86_400_000, # Never deactivate
    snapshot_timeout: 60_000        # Save every minute
end
```

### Event Processor

```elixir
defmodule MyApp.Actors.EventProcessor do
  use SpawnSdk.Actor,
    name: "event_processor",
    kind: :unnamed,
    stateful: false,               # Stateless for scalability
    channels: [
      {"events", "process_event"}
    ]
end
```

## Next Steps

- Learn about the [client API](client_api.md)
- Explore [advanced features](../advanced/) for complex interactions
- See [deployment guide](deployment.md) for production setup