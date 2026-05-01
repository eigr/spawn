# Supervision Tree Setup

This guide covers how to properly set up and configure your Spawn actor supervision tree in your Elixir application.

## Basic Setup

### Application Module

```elixir
defmodule MyApp.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {
        SpawnSdk.System.Supervisor,
        system: "spawn-system",
        actors: [
          MyApp.Actors.UserSession,
          MyApp.Actors.OrderProcessor,
          MyApp.Actors.ConfigManager
        ]
      }
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

## Configuration Options

### System Configuration

```elixir
{
  SpawnSdk.System.Supervisor,
  system: "my-actor-system",           # Required: system name
  actors: [...],                       # Required: list of actor modules
  external_subscribers: [...],         # Optional: external event subscribers  
  startup_timeout: 30_000,            # Optional: startup timeout in ms
  shutdown_timeout: 5_000              # Optional: shutdown timeout in ms
}
```

### system
- **Type:** String
- **Required:** Yes
- **Description:** Unique name for your actor system

```elixir
# Development system
system: "my-app-dev"

# Production system  
system: "my-app-prod"

# Multi-tenant systems
system: "tenant-#{tenant_id}"
```

### actors
- **Type:** List of modules
- **Required:** Yes
- **Description:** Actor modules to register in the system

```elixir
actors: [
  # Named actors
  MyApp.Actors.ConfigService,
  MyApp.Actors.StatsCollector,
  
  # Unnamed actors (for dynamic spawning)
  MyApp.Actors.UserSession,
  MyApp.Actors.ShoppingCart,
  MyApp.Actors.WorkerTask
]
```

## Multiple Actor Systems

You can run multiple actor systems in the same application:

```elixir
defmodule MyApp.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Primary system for business logic
      {
        SpawnSdk.System.Supervisor,
        system: "business-system",
        actors: [
          MyApp.Actors.UserService,
          MyApp.Actors.OrderService
        ]
      },
      
      # Secondary system for background tasks
      {
        SpawnSdk.System.Supervisor,
        system: "background-system", 
        actors: [
          MyApp.Actors.EmailProcessor,
          MyApp.Actors.ReportGenerator
        ]
      }
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

## External Subscribers

For integrating with Phoenix PubSub or other external systems:

### Basic External Subscriber

```elixir
defmodule MyApp.ExternalSubscriber do
  use GenServer
  require Logger

  alias SpawnSdk.Channel.Subscriber

  @impl true
  def init(state) do
    # Subscribe to actor broadcast events
    Subscriber.subscribe("user.events")
    {:ok, state}
  end

  @impl true
  def handle_info({:receive, payload}, state) do
    Logger.info("Received external event: #{inspect(payload)}")
    
    # Forward to Phoenix PubSub, LiveView, etc.
    Phoenix.PubSub.broadcast(MyApp.PubSub, "user_updates", {:user_event, payload})
    
    {:noreply, state}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end
end
```

### Registering External Subscribers

```elixir
defmodule MyApp.Application do
  use Application

  @impl true 
  def start(_type, _args) do
    children = [
      # Your regular supervision tree
      MyApp.PubSub,
      
      # Spawn system with external subscribers
      {
        SpawnSdk.System.Supervisor,
        system: "spawn-system",
        actors: [MyApp.Actors.UserActor],
        external_subscribers: [
          {MyApp.ExternalSubscriber, []},
          {MyApp.MetricsCollector, [interval: 5000]},
          {MyApp.EventLogger, [log_level: :info]}
        ]
      }
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

## Configuration Management

### Environment-Based Configuration

```elixir
defmodule MyApp.Application do
  use Application

  @impl true
  def start(_type, _args) do
    # Configure based on environment
    system_name = Application.get_env(:my_app, :actor_system, "my-app-#{Mix.env()}")
    
    actors = case Mix.env() do
      :test -> 
        [MyApp.Actors.TestUserActor]
      :prod -> 
        [
          MyApp.Actors.UserActor,
          MyApp.Actors.OrderActor,
          MyApp.Actors.PaymentActor
        ]
      _ -> 
        [
          MyApp.Actors.UserActor,
          MyApp.Actors.OrderActor
        ]
    end

    children = [
      {
        SpawnSdk.System.Supervisor,
        system: system_name,
        actors: actors
      }
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

### Runtime Configuration

```elixir
# config/runtime.exs
import Config

config :my_app,
  actor_system: System.get_env("ACTOR_SYSTEM_NAME", "my-app-prod"),
  actor_timeout: String.to_integer(System.get_env("ACTOR_TIMEOUT", "30000"))
```

## Health Monitoring

### Custom Health Check Actor

```elixir
defmodule MyApp.Actors.HealthCheck do
  use SpawnSdk.Actor,
    name: "health_check",
    stateful: false

  require Logger

  action "Ping", fn _ctx, _payload ->
    Logger.debug("Health check ping received")
    
    Value.of(%{
      status: "healthy",
      timestamp: DateTime.utc_now(),
      system: "spawn-system"
    })
  end

  # Timer-based health monitoring
  action "Monitor", [timer: 30_000], fn _ctx ->
    # Check system health periodically
    memory_usage = :erlang.memory()
    process_count = :erlang.system_info(:process_count)
    
    Logger.info("System health - Processes: #{process_count}, Memory: #{memory_usage[:total]}")
    
    Value.of()
  end
end
```

### Integration with Application Health

```elixir
defmodule MyApp.HealthController do
  use MyAppWeb, :controller

  def health(conn, _params) do
    case SpawnSdk.invoke("health_check", 
      system: "spawn-system", 
      action: "ping"
    ) do
      {:ok, status} ->
        json(conn, status)
        
      {:error, _reason} ->
        conn
        |> put_status(503)
        |> json(%{status: "unhealthy", error: "actor_system_down"})
    end
  end
end
```

## Development vs Production Setup

### Development Setup

```elixir
# config/dev.exs
config :my_app,
  actor_system: "my-app-dev",
  actors: [
    MyApp.Actors.UserSession,
    MyApp.Actors.TestDataGenerator  # Development-only actor
  ],
  external_subscribers: [
    {MyApp.DevSubscriber, []}  # Development event logging
  ]
```

### Production Setup

```elixir
# config/prod.exs  
config :my_app,
  actor_system: "my-app-prod",
  actors: [
    MyApp.Actors.UserSession,
    MyApp.Actors.OrderProcessor,
    MyApp.Actors.PaymentValidator,
    MyApp.Actors.MetricsCollector
  ],
  external_subscribers: [
    {MyApp.MetricsSubscriber, []},
    {MyApp.AlertSubscriber, []}
  ]
```

## Error Handling and Recovery

### Supervision Strategy

```elixir
defmodule MyApp.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Critical services first
      MyApp.Database,
      
      # Then actor system
      {
        SpawnSdk.System.Supervisor,
        system: "spawn-system",
        actors: actors_for_env()
      },
      
      # Less critical services last
      MyApp.MetricsServer
    ]

    # Use :one_for_one to isolate failures
    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp actors_for_env do
    base_actors = [
      MyApp.Actors.UserSession,
      MyApp.Actors.OrderProcessor
    ]

    case Mix.env() do
      :prod -> base_actors ++ [MyApp.Actors.MonitoringActor]
      _ -> base_actors
    end
  end
end
```

### Graceful Shutdown

```elixir
defmodule MyApp.Application do
  use Application

  @impl true
  def start(_type, _args) do
    # ... setup children ...
    
    # Handle graceful shutdown
    :ok = :gen_event.swap_handler(
      :erl_signal_server,
      {:erl_signal_handler, []},
      {MyApp.SignalHandler, []}
    )

    Supervisor.start_link(children, opts)
  end
end

defmodule MyApp.SignalHandler do
  @behaviour :gen_event

  def init(args), do: {:ok, args}

  def handle_event(:sigterm, state) do
    # Gracefully shutdown actors
    # Spawn system handles this automatically
    {:ok, state}
  end

  def handle_event(_signal, state), do: {:ok, state}
  def handle_call(_request, state), do: {:ok, :ok, state}
  def handle_info(_info, state), do: {:ok, state}
end
```

## Testing Setup

### Test Configuration

```elixir
# test/test_helper.exs
ExUnit.start()

# Setup test actor system
{:ok, _pid} = SpawnSdk.System.Supervisor.start_link(
  system: "test-system",
  actors: [
    MyApp.Actors.TestUser,
    MyApp.Actors.TestOrder
  ]
)
```

### Test Utilities

```elixir
defmodule MyApp.TestHelpers do
  def setup_test_system do
    SpawnSdk.System.Supervisor.start_link(
      system: "test-#{System.unique_integer()}",
      actors: [MyApp.Actors.TestActor]
    )
  end

  def with_test_actor(actor_name, actor_type, test_fun) do
    system = "test-#{System.unique_integer()}"
    
    {:ok, _} = SpawnSdk.System.Supervisor.start_link(
      system: system,
      actors: [actor_type]
    )

    SpawnSdk.spawn_actor(actor_name, system: system, actor: actor_type)
    
    try do
      test_fun.(system)
    after
      # Cleanup happens automatically when supervisor terminates
      :ok
    end
  end
end
```

## Best Practices

### Naming Conventions

```elixir
# Use descriptive system names
system: "ecommerce-system"     # Better than "system1"
system: "analytics-pipeline"   # Clear purpose
system: "user-management"      # Domain-specific

# Environment-specific names
system: "my-app-#{Mix.env()}"
system: "tenant-#{tenant_id}-system"
```

### Actor Organization

```elixir
# Group related actors
actors: [
  # User domain
  MyApp.Actors.UserSession,
  MyApp.Actors.UserProfile,
  
  # Order domain  
  MyApp.Actors.ShoppingCart,
  MyApp.Actors.OrderProcessor,
  
  # System actors
  MyApp.Actors.HealthMonitor,
  MyApp.Actors.ConfigManager
]
```

### Resource Management

```elixir
# Configure appropriate timeouts
{
  SpawnSdk.System.Supervisor,
  system: "spawn-system",
  actors: actors,
  startup_timeout: 60_000,    # Allow time for actor initialization
  shutdown_timeout: 10_000    # Graceful shutdown time
}
```

## Next Steps

- Learn about [deployment strategies](deployment.md)
- Explore [advanced patterns](../advanced/) for complex actor interactions
- See [monitoring and observability](monitoring.md) for production insights