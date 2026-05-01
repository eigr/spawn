# Broadcast

Broadcast allows actors to send messages to multiple subscribers simultaneously, enabling event-driven architectures and pub-sub patterns.

## Understanding Broadcast

Broadcast in Spawn enables:
- **One-to-many communication** - Send messages to multiple actors at once
- **Event-driven architectures** - Publish domain events that multiple services can react to
- **Decoupled systems** - Publishers don't need to know about subscribers
- **External integration** - Bridge with Phoenix PubSub and other external systems

## Basic Broadcast

### Publishing Events

```elixir
defmodule MyApp.Actors.OrderProcessor do
  use SpawnSdk.Actor,
    name: "order_processor",
    state_type: MyApp.Domain.OrderState

  alias SpawnSdk.Flow.Broadcast
  alias MyApp.Events.{OrderCreated, OrderUpdated}

  action "CreateOrder", fn %Context{state: state} = ctx, order_data ->
    # Process the order
    new_order = create_order(order_data)
    updated_state = add_order_to_state(state, new_order)

    # Create event
    order_event = %OrderCreated{
      order_id: new_order.id,
      user_id: new_order.user_id,
      amount: new_order.amount,
      created_at: DateTime.utc_now()
    }

    Value.of()
    |> Value.response(new_order)
    |> Value.state(updated_state)
    |> Value.broadcast(
      Broadcast.to("order.events", order_event)
    )
  end

  action "UpdateOrderStatus", fn %Context{state: state} = ctx, update_data ->
    # Update order status
    updated_order = update_order_status(state, update_data)
    new_state = update_order_in_state(state, updated_order)

    # Broadcast status change
    status_event = %OrderUpdated{
      order_id: updated_order.id,
      old_status: update_data.old_status,
      new_status: updated_order.status,
      updated_at: DateTime.utc_now()
    }

    Value.of()
    |> Value.response(updated_order)
    |> Value.state(new_state)
    |> Value.broadcast(
      Broadcast.to("order.status", status_event)
    )
  end
end
```

### Subscribing to Events

```elixir
defmodule MyApp.Actors.EmailService do
  use SpawnSdk.Actor,
    name: "email_service",
    channels: [
      {"order.events", "handle_order_event"},
      {"user.events", "handle_user_event"}
    ],
    stateful: false

  require Logger

  action "HandleOrderEvent", fn _ctx, %OrderCreated{} = event ->
    Logger.info("Sending order confirmation email for order #{event.order_id}")
    
    send_order_confirmation_email(event.user_id, event.order_id)
    
    Value.of(%{email_sent: true, order_id: event.order_id})
  end

  action "HandleOrderEvent", fn _ctx, %OrderUpdated{} = event ->
    Logger.info("Sending order status update email for order #{event.order_id}")
    
    send_status_update_email(event.order_id, event.new_status)
    
    Value.of(%{status_email_sent: true, order_id: event.order_id})
  end

  defp send_order_confirmation_email(user_id, order_id) do
    # Email sending logic
  end

  defp send_status_update_email(order_id, status) do
    # Status email logic
  end
end

defmodule MyApp.Actors.InventoryService do
  use SpawnSdk.Actor,
    name: "inventory_service", 
    channels: [
      {"order.events", "handle_order_event"}
    ],
    state_type: MyApp.Domain.InventoryState

  action "HandleOrderEvent", fn %Context{state: state} = ctx, %OrderCreated{} = event ->
    Logger.info("Updating inventory for order #{event.order_id}")
    
    # Reduce inventory
    updated_state = reduce_inventory(state, event.order_id)
    
    Value.of()
    |> Value.state(updated_state)
  end
end
```

## Multiple Channel Broadcasting

Send events to multiple channels simultaneously:

```elixir
defmodule MyApp.Actors.UserManager do
  use SpawnSdk.Actor,
    name: "user_manager",
    state_type: MyApp.Domain.UserManagerState

  action "CreateUser", fn %Context{state: state} = ctx, user_data ->
    # Create user
    new_user = create_user(user_data)
    updated_state = add_user_to_state(state, new_user)

    # Create different events for different audiences
    user_event = %UserCreated{
      user_id: new_user.id,
      email: new_user.email,
      created_at: DateTime.utc_now()
    }

    analytics_event = %UserSignup{
      user_id: new_user.id,
      signup_source: user_data.source,
      timestamp: DateTime.utc_now(),
      metadata: user_data.metadata
    }

    Value.of()
    |> Value.response(new_user)
    |> Value.state(updated_state)
    |> Value.broadcast(
      # Send to user events channel
      Broadcast.to("user.events", user_event)
      # Send to analytics channel
      |> Broadcast.to("analytics.events", analytics_event)
      # Send to audit channel
      |> Broadcast.to("audit.events", %AuditLog{
        action: "user_created",
        user_id: new_user.id,
        timestamp: DateTime.utc_now()
      })
    )
  end
end
```

## Channel Patterns

### Domain-Based Channels

```elixir
# User domain events
"user.events"        # All user-related events
"user.created"       # Specific user creation events
"user.updated"       # User update events
"user.deleted"       # User deletion events

# Order domain events  
"order.events"       # All order events
"order.created"      # New orders
"order.status"       # Status changes
"order.payment"      # Payment events

# System events
"system.alerts"      # System alerts
"system.metrics"     # Performance metrics
"system.audit"       # Audit trail
```

### Hierarchical Channel Subscriptions

```elixir
defmodule MyApp.Actors.AuditLogger do
  use SpawnSdk.Actor,
    name: "audit_logger",
    channels: [
      # Listen to all user events
      {"user.events", "log_user_event"},
      # Listen to all order events  
      {"order.events", "log_order_event"},
      # Listen to specific security events
      {"security.breach", "log_security_event"}
    ],
    stateful: false

  action "LogUserEvent", fn _ctx, event ->
    log_audit_event("USER", event)
    Value.of()
  end

  action "LogOrderEvent", fn _ctx, event ->
    log_audit_event("ORDER", event)
    Value.of()
  end

  action "LogSecurityEvent", fn _ctx, event ->
    # High priority logging
    log_security_breach(event)
    send_security_alert(event)
    Value.of()
  end
end
```

## External Broadcast Integration

### Phoenix PubSub Integration

```elixir
defmodule MyApp.ExternalEventSubscriber do
  @moduledoc """
  Subscribes to actor broadcasts and forwards them to Phoenix PubSub
  for LiveView integration.
  """
  use GenServer
  require Logger

  alias SpawnSdk.Channel.Subscriber

  @impl true
  def init(state) do
    # Subscribe to actor channels
    Subscriber.subscribe("user.events")
    Subscriber.subscribe("order.events") 
    Subscriber.subscribe("notification.events")
    
    {:ok, state}
  end

  @impl true
  def handle_info({:receive, payload}, state) do
    Logger.debug("Forwarding actor event to Phoenix PubSub: #{inspect(payload)}")
    
    # Forward to Phoenix PubSub based on event type
    case payload do
      %UserCreated{} = event ->
        Phoenix.PubSub.broadcast(MyApp.PubSub, "user_updates", {:user_created, event})
        
      %OrderCreated{} = event ->
        Phoenix.PubSub.broadcast(MyApp.PubSub, "order_updates", {:order_created, event})
        Phoenix.PubSub.broadcast(MyApp.PubSub, "user:#{event.user_id}", {:new_order, event})
        
      %NotificationEvent{} = event ->
        Phoenix.PubSub.broadcast(MyApp.PubSub, "notifications", {:notification, event})
        
      _ ->
        Logger.warn("Unknown event type: #{inspect(payload)}")
    end
    
    {:noreply, state}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
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
      # Phoenix PubSub
      {Phoenix.PubSub, name: MyApp.PubSub},
      
      # Spawn system with external subscribers
      {
        SpawnSdk.System.Supervisor,
        system: "spawn-system",
        actors: [
          MyApp.Actors.UserManager,
          MyApp.Actors.OrderProcessor,
          MyApp.Actors.EmailService
        ],
        external_subscribers: [
          {MyApp.ExternalEventSubscriber, []},
          {MyApp.MetricsCollector, []},
          {MyApp.WebhookNotifier, []}
        ]
      }
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

### LiveView Integration

```elixir
defmodule MyAppWeb.DashboardLive do
  use MyAppWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    # Subscribe to Phoenix PubSub topics that receive actor events
    Phoenix.PubSub.subscribe(MyApp.PubSub, "user_updates")
    Phoenix.PubSub.subscribe(MyApp.PubSub, "order_updates")
    
    {:ok, assign(socket, users: [], orders: [], notifications: [])}
  end

  @impl true
  def handle_info({:user_created, %UserCreated{} = event}, socket) do
    # Handle user created event from actors
    updated_users = [event | socket.assigns.users]
    {:noreply, assign(socket, users: updated_users)}
  end

  @impl true 
  def handle_info({:order_created, %OrderCreated{} = event}, socket) do
    # Handle order created event from actors
    updated_orders = [event | socket.assigns.orders]
    {:noreply, assign(socket, orders: updated_orders)}
  end
end
```

## Advanced Broadcast Patterns

### Event Sourcing with Broadcasts

```elixir
defmodule MyApp.Actors.EventSourcingAggregate do
  use SpawnSdk.Actor,
    name: "user_aggregate",
    kind: :unnamed,
    state_type: MyApp.Domain.UserAggregate

  action "UpdateProfile", fn %Context{state: state} = ctx, update_data ->
    # Apply business rules and generate events
    {updated_state, domain_events} = apply_profile_update(state, update_data)
    
    # Build broadcast for all generated events
    broadcast = domain_events
    |> Enum.reduce(Broadcast.new(), fn event, acc ->
      channel = channel_for_event(event)
      Broadcast.to(acc, channel, event)
    end)

    Value.of()
    |> Value.response(%{events_generated: length(domain_events)})
    |> Value.state(updated_state) 
    |> Value.broadcast(broadcast)
  end

  defp channel_for_event(%ProfileUpdated{}), do: "user.profile"
  defp channel_for_event(%EmailChanged{}), do: "user.email" 
  defp channel_for_event(%AddressChanged{}), do: "user.address"
  defp channel_for_event(_), do: "user.events"
end
```

### Saga Coordination via Broadcasts

```elixir
defmodule MyApp.Actors.OrderSaga do
  use SpawnSdk.Actor,
    name: "order_saga",
    kind: :unnamed,
    channels: [
      {"payment.events", "handle_payment_event"},
      {"inventory.events", "handle_inventory_event"}, 
      {"shipping.events", "handle_shipping_event"}
    ],
    state_type: MyApp.Domain.SagaState

  action "StartOrderSaga", fn ctx, %OrderCreated{} = event ->
    saga_state = %SagaState{
      order_id: event.order_id,
      steps: [:payment, :inventory, :shipping],
      completed_steps: [],
      status: :in_progress
    }

    # Start by triggering payment processing
    payment_command = %ProcessPayment{
      order_id: event.order_id,
      amount: event.amount,
      saga_id: "saga_#{event.order_id}"
    }

    Value.of()
    |> Value.state(saga_state)
    |> Value.broadcast(
      Broadcast.to("payment.commands", payment_command)
    )
  end

  action "HandlePaymentEvent", fn ctx, %PaymentProcessed{} = event ->
    updated_state = mark_step_completed(ctx.state, :payment)
    
    case next_step(updated_state) do
      :inventory ->
        # Trigger inventory reservation
        inventory_command = %ReserveInventory{
          order_id: event.order_id,
          items: event.order_items,
          saga_id: event.saga_id
        }
        
        Value.of()
        |> Value.state(updated_state)
        |> Value.broadcast(
          Broadcast.to("inventory.commands", inventory_command)
        )
        
      :completed ->
        # Saga completed successfully
        completion_event = %OrderSagaCompleted{
          order_id: event.order_id,
          completed_at: DateTime.utc_now()
        }
        
        Value.of()
        |> Value.state(%{updated_state | status: :completed})
        |> Value.broadcast(
          Broadcast.to("saga.events", completion_event)
        )
    end
  end
end
```

### Circuit Breaker with Health Broadcasting

```elixir
defmodule MyApp.Actors.HealthMonitor do
  use SpawnSdk.Actor,
    name: "health_monitor",
    state_type: MyApp.Domain.HealthState

  action "CheckHealth", [timer: 30_000], fn %Context{state: state} = ctx ->
    # Check various system components
    health_checks = perform_health_checks()
    
    # Update health state
    new_state = update_health_state(state, health_checks)
    
    # Broadcast health status
    health_event = %HealthStatusUpdate{
      timestamp: DateTime.utc_now(),
      overall_status: new_state.overall_status,
      component_statuses: health_checks,
      previous_status: state.overall_status
    }

    broadcast = case {state.overall_status, new_state.overall_status} do
      {:healthy, :unhealthy} ->
        # System became unhealthy - alert immediately
        Broadcast.to("system.alerts", %SystemAlert{
          level: :critical,
          message: "System health degraded",
          timestamp: DateTime.utc_now()
        })
        |> Broadcast.to("health.events", health_event)
        
      {:unhealthy, :healthy} ->
        # System recovered - celebrate
        Broadcast.to("system.alerts", %SystemAlert{
          level: :info, 
          message: "System health recovered",
          timestamp: DateTime.utc_now()
        })
        |> Broadcast.to("health.events", health_event)
        
      _ ->
        # Regular health update
        Broadcast.to("health.events", health_event)
    end

    Value.of()
    |> Value.state(new_state)
    |> Value.broadcast(broadcast)
  end
end
```

## Performance Considerations

### Efficient Broadcasting

```elixir
# Good: Batch related events
action "ProcessBulkOrders", fn ctx, orders ->
  processed_orders = Enum.map(orders, &process_order/1)
  
  # Single broadcast with all events
  events = Enum.map(processed_orders, fn order ->
    %OrderCreated{order_id: order.id, user_id: order.user_id}
  end)
  
  batch_event = %BulkOrdersProcessed{
    orders: events,
    processed_at: DateTime.utc_now()
  }

  Value.of()
  |> Value.response(processed_orders)
  |> Value.broadcast(Broadcast.to("order.events", batch_event))
end

# Avoid: Too many individual broadcasts  
action "ProcessOrdersInefficiently", fn ctx, orders ->
  Enum.each(orders, fn order ->
    # This creates too many individual broadcasts
    Value.of()
    |> Value.broadcast(Broadcast.to("order.events", %OrderCreated{...}))
  end)
end
```

### Channel Organization

```elixir
# Good: Organized channel hierarchy
"domain.aggregate.event"     # user.profile.updated
"domain.action"              # payment.processed  
"system.component.metric"    # database.performance.slow_query

# Avoid: Flat channel names
"user_updated"
"payment_done"
"slow_db"
```

## Testing Broadcasts

```elixir
defmodule MyApp.BroadcastTest do
  use ExUnit.Case

  setup do
    # Setup test subscribers to capture broadcast events
    {:ok, subscriber_pid} = start_test_subscriber()
    
    {:ok, _} = SpawnSdk.System.Supervisor.start_link(
      system: "test-system",
      actors: [MyApp.Actors.OrderProcessor, MyApp.Actors.EmailService],
      external_subscribers: [{TestEventSubscriber, [test_pid: subscriber_pid]}]
    )
    
    %{subscriber: subscriber_pid}
  end

  test "order creation broadcasts event", %{subscriber: subscriber} do
    # Create order
    {:ok, order} = SpawnSdk.invoke("order_processor",
      system: "test-system",
      action: "create_order",
      payload: %OrderData{user_id: "user_123", amount: 100}
    )

    # Wait for broadcast to be received
    assert_receive {:broadcast_received, "order.events", %OrderCreated{} = event}, 1000
    
    assert event.order_id == order.id
    assert event.user_id == "user_123"
    assert event.amount == 100
  end
end

defmodule TestEventSubscriber do
  use GenServer
  alias SpawnSdk.Channel.Subscriber

  def init([test_pid: test_pid]) do
    Subscriber.subscribe("order.events")
    Subscriber.subscribe("user.events")
    {:ok, %{test_pid: test_pid}}
  end

  def handle_info({:receive, payload}, %{test_pid: test_pid} = state) do
    send(test_pid, {:broadcast_received, "order.events", payload})
    {:noreply, state}
  end
end
```

## Best Practices

### Event Design

```elixir
# Good: Rich, descriptive events
%OrderCreated{
  order_id: "ord_123",
  user_id: "user_456", 
  amount: 100.00,
  currency: "USD",
  items: [%{sku: "item_1", quantity: 2}],
  created_at: ~U[2023-12-01 10:00:00Z],
  version: 1
}

# Avoid: Sparse events
%OrderEvent{type: "created", id: "ord_123"}
```

### Channel Naming

```elixir
# Use consistent patterns
"domain.entity.action"     # user.profile.updated
"system.component"         # database.health
"integration.external"     # webhook.shopify
```

### Error Handling

```elixir
# Handle broadcast failures gracefully
action "SafeBroadcast", fn ctx, data ->
  try do
    Value.of()
    |> Value.response(data)
    |> Value.broadcast(Broadcast.to("events", data))
  rescue
    error ->
      Logger.error("Broadcast failed: #{inspect(error)}")
      # Continue without broadcast
      Value.of(data)
  end
end
```

## Next Steps

- Learn about [timers and scheduling](timers.md)
- Explore [event-driven patterns](event_driven_patterns.md)
- See [monitoring broadcasts](../observability/monitoring.md) for production insights