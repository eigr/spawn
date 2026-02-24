# Side Effects

Side effects allow actors to trigger actions on other actors asynchronously as part of their response flow. This is a powerful pattern for event-driven architectures and decoupled systems.

## Understanding Side Effects

Side effects are **fire-and-forget** operations that:
- Execute asynchronously after the main action completes
- Don't affect the request-response flow  
- Don't return responses to the triggering actor
- Can be delayed or scheduled for specific times

## Basic Side Effect

```elixir
defmodule MyApp.Actors.OrderProcessor do
  use SpawnSdk.Actor,
    name: "order_processor",
    state_type: MyApp.Domain.OrderState

  alias SpawnSdk.Flow.SideEffect
  alias MyApp.Messages.{OrderCreated, NotificationRequest}

  action "ProcessOrder", fn %Context{} = ctx, %OrderCreated{} = order ->
    # Main business logic
    processed_order = process_order_logic(order)
    new_state = %OrderState{orders: [processed_order | ctx.state.orders]}

    # Return response with side effect
    Value.of()
    |> Value.response(processed_order)
    |> Value.state(new_state)
    |> Value.effects([
      # Send notification asynchronously
      SideEffect.of()
      |> SideEffect.effect(
        "notification_service",
        :send_notification,
        %NotificationRequest{
          user_id: order.user_id,
          message: "Order #{order.id} has been processed"
        }
      )
    ])
  end

  defp process_order_logic(order) do
    # Your business logic here
    %{order | status: :processed, processed_at: DateTime.utc_now()}
  end
end
```

## Multiple Side Effects

You can chain multiple side effects together:

```elixir
action "CompletePayment", fn ctx, payment_data ->
  # Process payment
  payment_result = process_payment(payment_data)
  
  Value.of()
  |> Value.response(payment_result)
  |> Value.state(update_payment_state(ctx.state, payment_result))
  |> Value.effects([
    # Update inventory
    SideEffect.of()
    |> SideEffect.effect("inventory_service", :reduce_stock, %{
      product_id: payment_data.product_id,
      quantity: payment_data.quantity
    })
    # Send confirmation email  
    |> SideEffect.effect("email_service", :send_confirmation, %{
      user_id: payment_data.user_id,
      payment_id: payment_result.id
    })
    # Update analytics
    |> SideEffect.effect("analytics_service", :record_purchase, %{
      user_id: payment_data.user_id,
      amount: payment_data.amount,
      timestamp: DateTime.utc_now()
    })
  ])
end
```

## Delayed Side Effects

Execute side effects after a specified delay:

```elixir
action "CreateUserAccount", fn ctx, user_data ->
  # Create account immediately
  new_user = create_user_account(user_data)
  
  Value.of()
  |> Value.response(new_user)
  |> Value.state(add_user_to_state(ctx.state, new_user))
  |> Value.effects([
    # Send welcome email after 5 minutes
    SideEffect.of()
    |> SideEffect.effect(
      "email_service", 
      :send_welcome_email, 
      %{user_id: new_user.id},
      delay: 300_000  # 5 minutes
    )
    # Schedule follow-up email after 24 hours
    |> SideEffect.effect(
      "email_service",
      :send_followup_email,
      %{user_id: new_user.id},
      delay: 86_400_000  # 24 hours
    )
  ])
end
```

## Scheduled Side Effects

Schedule side effects for specific dates/times:

```elixir
action "ScheduleReminder", fn ctx, reminder_data ->
  # Store reminder immediately
  new_state = add_reminder(ctx.state, reminder_data)
  
  Value.of()
  |> Value.response(%{reminder_id: reminder_data.id, scheduled: true})
  |> Value.state(new_state)
  |> Value.effects([
    # Execute reminder at specific time
    SideEffect.of()
    |> SideEffect.effect(
      "notification_service",
      :send_reminder,
      %{
        user_id: reminder_data.user_id,
        message: reminder_data.message
      },
      scheduled_to: reminder_data.scheduled_time
    )
  ])
end
```

## Side Effect Patterns

### Event Sourcing Pattern

```elixir
defmodule MyApp.Actors.AggregateRoot do
  use SpawnSdk.Actor,
    name: "user_aggregate",
    kind: :unnamed,
    state_type: MyApp.Domain.UserAggregate

  action "UpdateProfile", fn ctx, update_data ->
    # Apply business logic
    {updated_state, events} = apply_profile_update(ctx.state, update_data)
    
    # Build side effects from domain events
    effects = events
    |> Enum.reduce(SideEffect.of(), fn event, acc ->
      case event do
        %ProfileUpdated{} = event ->
          acc |> SideEffect.effect("event_store", :store_event, event)
          
        %EmailChanged{} = event ->
          acc 
          |> SideEffect.effect("event_store", :store_event, event)
          |> SideEffect.effect("email_service", :send_verification, %{
            user_id: event.user_id,
            email: event.new_email
          })
      end
    end)
    
    Value.of()
    |> Value.response(%{success: true, events: length(events)})
    |> Value.state(updated_state)
    |> Value.effects(effects)
  end
end
```

### Saga Pattern

```elixir
defmodule MyApp.Actors.OrderSaga do
  use SpawnSdk.Actor,
    name: "order_saga",
    kind: :unnamed,
    state_type: MyApp.Domain.SagaState

  action "StartOrderProcess", fn ctx, order_data ->
    # Initialize saga state
    saga_state = %SagaState{
      order_id: order_data.id,
      step: :payment_processing,
      steps_completed: [],
      compensations: []
    }
    
    Value.of()
    |> Value.response(%{saga_started: true, saga_id: order_data.id})
    |> Value.state(saga_state)
    |> Value.effects([
      # Start first step
      SideEffect.of()
      |> SideEffect.effect("payment_service", :process_payment, order_data)
    ])
  end

  action "PaymentCompleted", fn ctx, payment_result ->
    next_state = %{ctx.state | 
      step: :inventory_reservation,
      steps_completed: [:payment_processing | ctx.state.steps_completed]
    }
    
    Value.of()
    |> Value.state(next_state)
    |> Value.effects([
      # Continue to next step
      SideEffect.of()
      |> SideEffect.effect("inventory_service", :reserve_items, %{
        order_id: ctx.state.order_id,
        items: payment_result.items
      })
    ])
  end

  action "PaymentFailed", fn ctx, failure_reason ->
    # Saga failed - no compensation needed for first step
    failed_state = %{ctx.state | step: :failed, failure_reason: failure_reason}
    
    Value.of()
    |> Value.state(failed_state)
    |> Value.effects([
      SideEffect.of()
      |> SideEffect.effect("notification_service", :send_failure_notification, %{
        order_id: ctx.state.order_id,
        reason: failure_reason
      })
    ])
  end
end
```

### Circuit Breaker Pattern

```elixir
defmodule MyApp.Actors.ResilientProcessor do
  use SpawnSdk.Actor,
    name: "resilient_processor",
    state_type: MyApp.Domain.ProcessorState

  action "ProcessWithFallback", fn ctx, data ->
    case ctx.state.circuit_state do
      :closed ->
        # Normal processing with fallback side effect
        Value.of()
        |> Value.response(process_normally(data))
        |> Value.state(ctx.state)
        |> Value.effects([
          # If main processing fails, this fallback will be triggered
          SideEffect.of()
          |> SideEffect.effect(
            "fallback_processor", 
            :process_fallback, 
            data,
            delay: 1000  # Small delay for fallback
          )
        ])
        
      :open ->
        # Circuit is open, use fallback immediately
        Value.of()
        |> Value.response(%{status: :fallback_used})
        |> Value.state(ctx.state)
        |> Value.effects([
          SideEffect.of()
          |> SideEffect.effect("fallback_processor", :process_fallback, data)
        ])
    end
  end
end
```

## Error Handling in Side Effects

Side effects are fire-and-forget, but you can implement error handling patterns:

### Dead Letter Queue Pattern

```elixir
defmodule MyApp.Actors.ReliableProcessor do
  use SpawnSdk.Actor,
    name: "reliable_processor",
    state_type: MyApp.Domain.ProcessorState

  action "ProcessReliably", fn ctx, data ->
    Value.of()
    |> Value.response(process_data(data))
    |> Value.state(ctx.state)
    |> Value.effects([
      # Primary side effect
      SideEffect.of()
      |> SideEffect.effect("primary_service", :process, data)
      # Delayed verification and retry
      |> SideEffect.effect(
        "verification_service",
        :verify_processing,
        %{data_id: data.id, expected_completion: DateTime.add(DateTime.utc_now(), 30)},
        delay: 35_000  # Check after 35 seconds
      )
    ])
  end
end

defmodule MyApp.Actors.VerificationService do
  use SpawnSdk.Actor,
    name: "verification_service",
    stateful: false

  action "VerifyProcessing", fn _ctx, verification_data ->
    case check_processing_completion(verification_data.data_id) do
      :completed ->
        Value.of(%{status: :verified})
        
      :failed ->
        # Send to dead letter queue or retry
        Value.of()
        |> Value.effects([
          SideEffect.of()
          |> SideEffect.effect("dead_letter_queue", :store_failed, verification_data)
        ])
    end
  end
end
```

## Advanced Side Effect Patterns

### Event Bus Pattern

```elixir
defmodule MyApp.Actors.EventPublisher do
  use SpawnSdk.Actor,
    name: "event_publisher",
    stateful: false

  action "PublishEvent", fn _ctx, event_data ->
    # Publish to multiple subscribers via side effects
    subscribers = get_subscribers_for_event(event_data.event_type)
    
    effects = subscribers
    |> Enum.reduce(SideEffect.of(), fn subscriber, acc ->
      acc |> SideEffect.effect(subscriber.actor, subscriber.action, event_data)
    end)

    Value.of()
    |> Value.response(%{published: true, subscriber_count: length(subscribers)})
    |> Value.effects(effects)
  end

  defp get_subscribers_for_event("user.created") do
    [
      %{actor: "email_service", action: "send_welcome"},
      %{actor: "analytics_service", action: "track_signup"},
      %{actor: "recommendation_service", action: "initialize_profile"}
    ]
  end
end
```

### Distributed State Synchronization

```elixir
defmodule MyApp.Actors.DistributedCache do
  use SpawnSdk.Actor,
    name: "distributed_cache",
    kind: :unnamed,
    state_type: MyApp.Domain.CacheState

  action "UpdateCache", fn ctx, update_data ->
    # Update local state
    new_state = apply_cache_update(ctx.state, update_data)
    
    # Synchronize with other cache instances
    other_instances = get_other_cache_instances()
    
    sync_effects = other_instances
    |> Enum.reduce(SideEffect.of(), fn instance, acc ->
      acc |> SideEffect.effect(instance, :sync_update, update_data)
    end)

    Value.of()
    |> Value.response(%{updated: true})
    |> Value.state(new_state)
    |> Value.effects(sync_effects)
  end
end
```

## Best Practices

### Side Effect Design Principles

1. **Keep side effects idempotent** - They may be retried
2. **Make them atomic** - Each side effect should be a single, complete operation
3. **Use appropriate delays** - Don't overwhelm target actors
4. **Handle failures gracefully** - Consider what happens if side effects fail

### Performance Considerations

```elixir
# Good: Batch related side effects
SideEffect.of()
|> SideEffect.effect("batch_processor", :process_batch, %{
  items: [item1, item2, item3]
})

# Avoid: Too many individual side effects
SideEffect.of()
|> SideEffect.effect("processor", :process_item, item1)
|> SideEffect.effect("processor", :process_item, item2)
|> SideEffect.effect("processor", :process_item, item3)
```

### Monitoring Side Effects

```elixir
action "ProcessWithMonitoring", fn ctx, data ->
  correlation_id = UUID.uuid4()
  
  Value.of()
  |> Value.response(%{correlation_id: correlation_id})
  |> Value.state(ctx.state)
  |> Value.effects([
    # Main side effect with correlation ID
    SideEffect.of()
    |> SideEffect.effect("target_service", :process, %{
      data: data,
      correlation_id: correlation_id
    })
    # Monitoring side effect
    |> SideEffect.effect("monitoring_service", :track_side_effect, %{
      correlation_id: correlation_id,
      source_actor: ctx.actor_name,
      target_actor: "target_service",
      timestamp: DateTime.utc_now()
    })
  ])
end
```

## Testing Side Effects

```elixir
defmodule MyApp.ActorTest do
  use ExUnit.Case

  test "side effects are triggered correctly" do
    # Setup test actors
    {:ok, _} = SpawnSdk.spawn_actor("test_processor", 
      system: "test-system", 
      actor: "order_processor"
    )
    
    # Mock the side effect target
    {:ok, _} = SpawnSdk.spawn_actor("mock_notification_service",
      system: "test-system",
      actor: "mock_notification_service"
    )

    # Invoke main action
    {:ok, response} = SpawnSdk.invoke("test_processor",
      system: "test-system",
      action: "process_order",
      payload: %OrderCreated{id: "123", user_id: "user1"}
    )

    # Verify main response
    assert response.status == :processed

    # Wait for side effect to complete (in real tests, use proper synchronization)
    :timer.sleep(100)

    # Verify side effect was executed
    {:ok, notification_state} = SpawnSdk.invoke("mock_notification_service",
      system: "test-system",
      action: "get"
    )
    
    assert length(notification_state.sent_notifications) == 1
  end
end
```

## Next Steps

- Learn about [forward and pipe patterns](forwards_and_pipes.md)
- Explore [broadcast messaging](broadcast.md)
- See [monitoring and debugging](../observability/debugging.md) for side effect troubleshooting