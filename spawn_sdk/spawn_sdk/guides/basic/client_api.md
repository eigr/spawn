# Client API

This guide covers the complete client API for interacting with Spawn actors from your Elixir application.

## Basic Invocation

### SpawnSdk.invoke/2

The primary function for calling actor actions.

```elixir
# Basic invocation
SpawnSdk.invoke(actor_name, options)
```

#### Parameters

- `actor_name` - String name of the actor to invoke
- `options` - Keyword list of invocation options

#### Basic Example

```elixir
iex> SpawnSdk.invoke("counter", 
  system: "spawn-system", 
  action: "increment", 
  payload: %MyApp.Messages.IncrementMessage{value: 5}
)
{:ok, %MyApp.Messages.CounterResponse{value: 15}}
```

## Invocation Options

### Required Options

```elixir
# system - The actor system name
system: "spawn-system"

# action - The action to call on the actor
action: "my_action"
```

### Optional Options

```elixir
# payload - Data to send to the actor
payload: %MyMessage{data: "hello"}

# ref - For unnamed actors, specifies the actor type
ref: "user_session"

# pooled - Use pooled invocation for load balancing
pooled: true

# delay - Delay execution by milliseconds
delay: 5_000

# scheduled_to - Schedule for specific DateTime
scheduled_to: ~U[2023-12-25 10:00:00Z]

# revision - Restore actor from specific revision
revision: 42
```

## Default Actions

Actors have built-in actions that don't require custom implementation:

### Get State

```elixir
# Get current actor state
iex> SpawnSdk.invoke("user_123", system: "spawn-system", action: "get")
{:ok, %MyApp.Domain.UserState{name: "John", balance: 100}}

# Alternative action names that work the same way:
action: "Get"
action: "get_state"  
action: "getState"
action: "GetState"
```

## Working with Named Actors

Named actors are pre-registered and always available:

```elixir
# Invoke a named actor directly
iex> SpawnSdk.invoke("config_manager", 
  system: "spawn-system", 
  action: "get_config", 
  payload: %ConfigRequest{key: "database_url"}
)
{:ok, %ConfigResponse{value: "postgres://..."}}

# Get named actor state
iex> SpawnSdk.invoke("config_manager", system: "spawn-system", action: "get")
{:ok, %ConfigState{settings: %{...}}}
```

## Working with Unnamed Actors

Unnamed actors must be spawned before use, or you can use lazy spawning:

### Explicit Spawning

```elixir
# First, spawn the actor
iex> SpawnSdk.spawn_actor("user_123", 
  system: "spawn-system", 
  actor: "user_session"
)
:ok

# Then invoke it
iex> SpawnSdk.invoke("user_123", 
  system: "spawn-system", 
  action: "login", 
  payload: %LoginRequest{username: "john"}
)
{:ok, %LoginResponse{success: true}}
```

### Lazy Spawning

```elixir
# Spawn and invoke in one call using `ref`
iex> SpawnSdk.invoke("user_456", 
  ref: "user_session",
  system: "spawn-system", 
  action: "login", 
  payload: %LoginRequest{username: "jane"}
)
{:ok, %LoginResponse{success: true}}
```

### Spawning with Revision

```elixir
# Restore actor from specific point in time
iex> SpawnSdk.spawn_actor("user_789", 
  system: "spawn-system", 
  actor: "user_session", 
  revision: 15
)
:ok
```

## Pooled Invocations

For stateless, load-balanced operations:

```elixir
# System automatically selects an available instance
iex> SpawnSdk.invoke("image_processor", 
  system: "spawn-system", 
  action: "resize_image", 
  payload: %ImageRequest{url: "...", width: 800},
  pooled: true
)
{:ok, %ImageResponse{processed_url: "..."}}
```

## Scheduled and Delayed Invocations

### Delayed Execution

```elixir
# Execute after 5 seconds
iex> SpawnSdk.invoke("notification_service", 
  system: "spawn-system", 
  action: "send_reminder", 
  payload: %ReminderRequest{user_id: 123, message: "Meeting in 5 minutes"},
  delay: 5_000
)
{:ok, :async}
```

### Scheduled Execution

```elixir
# Execute at specific time
iex> SpawnSdk.invoke("report_generator", 
  system: "spawn-system", 
  action: "generate_daily_report", 
  payload: %ReportRequest{date: "2023-12-25"},
  scheduled_to: ~U[2023-12-25 23:59:00Z]
)
{:ok, :async}
```

## Error Handling

### Common Error Patterns

```elixir
case SpawnSdk.invoke("my_actor", system: "spawn-system", action: "my_action") do
  {:ok, response} ->
    # Success - handle response
    IO.inspect(response)
    
  {:error, :not_found} ->
    # Actor not found
    Logger.error("Actor not found")
    
  {:error, :timeout} ->
    # Request timed out
    Logger.error("Request timeout")
    
  {:error, reason} ->
    # Other errors
    Logger.error("Invocation failed: #{inspect(reason)}")
end
```

### Async Responses

Delayed and scheduled invocations return `:async`:

```elixir
case SpawnSdk.invoke("actor", options ++ [delay: 1000]) do
  {:ok, :async} ->
    Logger.info("Request scheduled successfully")
    
  {:error, reason} ->
    Logger.error("Failed to schedule request: #{inspect(reason)}")
end
```

## Advanced Patterns

### Conditional Invocation

```elixir
defmodule MyApp.ActorClient do
  def call_user_actor(user_id, action, payload) do
    # Check if user exists first
    case SpawnSdk.invoke("user_#{user_id}", system: "spawn-system", action: "get") do
      {:ok, _user_state} ->
        # User exists, proceed with action
        SpawnSdk.invoke("user_#{user_id}", 
          system: "spawn-system", 
          action: action, 
          payload: payload
        )
        
      {:error, :not_found} ->
        # Lazy spawn and invoke
        SpawnSdk.invoke("user_#{user_id}", 
          ref: "user_session",
          system: "spawn-system", 
          action: action, 
          payload: payload
        )
    end
  end
end
```

### Bulk Operations

```elixir
defmodule MyApp.BulkOperations do
  def broadcast_to_users(user_ids, message) do
    tasks = Enum.map(user_ids, fn user_id ->
      Task.async(fn ->
        SpawnSdk.invoke("user_#{user_id}", 
          ref: "user_session",
          system: "spawn-system", 
          action: "receive_message", 
          payload: message
        )
      end)
    end)
    
    # Wait for all to complete
    results = Task.await_many(tasks, 5_000)
    
    # Process results
    {successes, failures} = Enum.split_with(results, &match?({:ok, _}, &1))
    
    %{
      success_count: length(successes),
      failure_count: length(failures),
      failures: failures
    }
  end
end
```

### Circuit Breaker Pattern

```elixir
defmodule MyApp.SafeActorClient do
  @max_retries 3
  @retry_delay 1_000

  def safe_invoke(actor, opts, retries \\ 0) do
    case SpawnSdk.invoke(actor, opts) do
      {:ok, response} ->
        {:ok, response}
        
      {:error, :timeout} when retries < @max_retries ->
        :timer.sleep(@retry_delay)
        safe_invoke(actor, opts, retries + 1)
        
      {:error, reason} ->
        Logger.error("Actor invocation failed after #{retries} retries: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
```

## Performance Tips

### Batch Similar Requests

```elixir
# Instead of multiple calls
Enum.each(user_ids, fn id ->
  SpawnSdk.invoke("user_#{id}", system: "spawn-system", action: "update")
end)

# Use async tasks for parallel execution
user_ids
|> Enum.map(&Task.async(fn -> 
    SpawnSdk.invoke("user_#{&1}", system: "spawn-system", action: "update") 
   end))
|> Task.await_many()
```

### Use Pooled Actors for Stateless Operations

```elixir
# Instead of creating many unnamed actors
SpawnSdk.invoke("processor_#{unique_id}", ...)

# Use pooled actors for better resource utilization  
SpawnSdk.invoke("processor", pooled: true, ...)
```

### Minimize Payload Size

```elixir
# Instead of sending large objects
payload = %HugeDataStructure{...}

# Send references and let actors fetch data
payload = %DataReference{id: data_id}
```

## Testing with Actors

### Test Helper

```elixir
defmodule MyApp.TestHelpers do
  def setup_test_actor(name, actor_type) do
    SpawnSdk.spawn_actor(name, 
      system: "test-system", 
      actor: actor_type
    )
  end

  def cleanup_test_actor(name) do
    # Actors auto-deactivate, but you can force cleanup if needed
    SpawnSdk.invoke(name, 
      system: "test-system", 
      action: "deactivate"
    )
  end
end
```

### Integration Test Example

```elixir
defmodule MyApp.ActorIntegrationTest do
  use ExUnit.Case
  import MyApp.TestHelpers

  test "user session workflow" do
    user_id = "test_user_#{System.unique_integer()}"
    
    # Setup
    setup_test_actor(user_id, "user_session")
    
    # Test login
    {:ok, response} = SpawnSdk.invoke(user_id,
      system: "test-system",
      action: "login", 
      payload: %LoginRequest{username: "test"}
    )
    
    assert response.success == true
    
    # Test state persistence
    {:ok, state} = SpawnSdk.invoke(user_id, 
      system: "test-system", 
      action: "get"
    )
    
    assert state.username == "test"
    
    # Cleanup
    cleanup_test_actor(user_id)
  end
end
```

## Next Steps

- Learn about [supervision tree setup](supervision.md)
- Explore [advanced patterns](../advanced/) like side effects and forwards
- Check out [deployment strategies](deployment.md)