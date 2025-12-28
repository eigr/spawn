# Forwards and Pipes

Forwards and pipes allow actors to route requests to other actors as part of their response flow, enabling powerful composition and delegation patterns.

## Understanding Forwards vs Pipes

### Forward
- Passes the **original request payload** to the target actor
- The original actor's response is **replaced** by the target actor's response
- The target actor receives exactly what the original actor received

### Pipe  
- Passes the **current response** to the target actor
- The original response is transformed by the target actor
- Creates a processing pipeline

## Basic Forward Example

```elixir
defmodule MyApp.Actors.Router do
  use SpawnSdk.Actor,
    name: "request_router",
    stateful: false

  alias SpawnSdk.Flow.Forward

  action "RoutePayment", fn _ctx, %PaymentRequest{} = payment ->
    Logger.info("Routing payment request: #{payment.amount}")

    # Determine which payment processor to use
    processor = case payment.payment_method do
      :credit_card -> "credit_card_processor"
      :paypal -> "paypal_processor"
      :bank_transfer -> "bank_processor"
    end

    Value.of()
    |> Value.forward(Forward.to(processor, "process_payment"))
    |> Value.void()
  end
end

defmodule MyApp.Actors.CreditCardProcessor do
  use SpawnSdk.Actor,
    name: "credit_card_processor",
    stateful: false

  action "ProcessPayment", fn _ctx, %PaymentRequest{} = payment ->
    # The payment request is exactly what was sent to the router
    Logger.info("Processing credit card payment: #{payment.amount}")
    
    result = process_credit_card(payment)
    
    Value.of(%PaymentResponse{
      status: :success,
      transaction_id: result.transaction_id,
      amount: payment.amount
    })
  end
end
```

**Usage:**
```elixir
# Client sends to router, gets response from credit card processor
iex> SpawnSdk.invoke("request_router", 
  system: "spawn-system", 
  action: "route_payment",
  payload: %PaymentRequest{amount: 100, payment_method: :credit_card}
)
{:ok, %PaymentResponse{status: :success, transaction_id: "txn_123", amount: 100}}
```

## Basic Pipe Example

```elixir
defmodule MyApp.Actors.DataProcessor do
  use SpawnSdk.Actor,
    name: "data_processor",
    stateful: false

  alias SpawnSdk.Flow.Pipe

  action "ProcessData", fn _ctx, %DataRequest{} = data ->
    Logger.info("Initial data processing")
    
    # Transform the data
    processed_data = %ProcessedData{
      original_data: data.raw_data,
      timestamp: DateTime.utc_now(),
      processed_by: "data_processor"
    }

    Value.of()
    |> Value.response(processed_data)
    |> Value.pipe(Pipe.to("data_enricher", "enrich_data"))
    |> Value.void()
  end
end

defmodule MyApp.Actors.DataEnricher do
  use SpawnSdk.Actor,
    name: "data_enricher", 
    stateful: false

  action "EnrichData", fn _ctx, %ProcessedData{} = data ->
    # Receives the ProcessedData from data_processor
    Logger.info("Enriching processed data")
    
    enriched_data = %EnrichedData{
      original_data: data.original_data,
      processed_timestamp: data.timestamp,
      processed_by: data.processed_by,
      enriched_at: DateTime.utc_now(),
      enriched_by: "data_enricher",
      metadata: %{source: "external_api", confidence: 0.95}
    }

    Value.of(enriched_data)
  end
end
```

**Usage:**
```elixir
# Client sends DataRequest, gets back EnrichedData
iex> SpawnSdk.invoke("data_processor",
  system: "spawn-system",
  action: "process_data", 
  payload: %DataRequest{raw_data: "user input"}
)
{:ok, %EnrichedData{
  original_data: "user input",
  processed_timestamp: ~U[2023-12-01 10:00:00Z],
  enriched_at: ~U[2023-12-01 10:00:01Z],
  metadata: %{source: "external_api", confidence: 0.95}
}}
```

## Chain Processing with Multiple Pipes

```elixir
defmodule MyApp.Actors.DocumentProcessor do
  use SpawnSdk.Actor,
    name: "document_processor",
    stateful: false

  action "ProcessDocument", fn _ctx, %DocumentRequest{} = doc ->
    # Stage 1: Parse document
    parsed_doc = %ParsedDocument{
      content: parse_content(doc.raw_content),
      format: doc.format,
      size: byte_size(doc.raw_content)
    }

    Value.of()
    |> Value.response(parsed_doc)
    |> Value.pipe(Pipe.to("content_analyzer", "analyze_content"))
    |> Value.void()
  end
end

defmodule MyApp.Actors.ContentAnalyzer do
  use SpawnSdk.Actor,
    name: "content_analyzer",
    stateful: false

  action "AnalyzeContent", fn _ctx, %ParsedDocument{} = doc ->
    # Stage 2: Analyze content  
    analyzed_doc = %AnalyzedDocument{
      content: doc.content,
      format: doc.format,
      size: doc.size,
      sentiment: analyze_sentiment(doc.content),
      keywords: extract_keywords(doc.content),
      language: detect_language(doc.content)
    }

    Value.of()
    |> Value.response(analyzed_doc) 
    |> Value.pipe(Pipe.to("content_summarizer", "summarize_content"))
    |> Value.void()
  end
end

defmodule MyApp.Actors.ContentSummarizer do
  use SpawnSdk.Actor,
    name: "content_summarizer",
    stateful: false

  action "SummarizeContent", fn _ctx, %AnalyzedDocument{} = doc ->
    # Stage 3: Generate summary
    summary = %DocumentSummary{
      original_size: doc.size,
      format: doc.format,
      sentiment: doc.sentiment,
      keywords: doc.keywords,
      language: doc.language,
      summary: generate_summary(doc.content),
      processing_chain: ["document_processor", "content_analyzer", "content_summarizer"]
    }

    Value.of(summary)
  end
end
```

## Conditional Forwarding

```elixir
defmodule MyApp.Actors.SmartRouter do
  use SpawnSdk.Actor,
    name: "smart_router",
    state_type: MyApp.Domain.RouterState

  action "RouteRequest", fn %Context{state: state} = ctx, request ->
    # Update routing metrics
    new_state = update_routing_stats(state, request)
    
    # Determine routing based on load, request type, etc.
    target = determine_target(request, state)
    
    case target do
      {:forward, actor, action} ->
        Value.of()
        |> Value.state(new_state)
        |> Value.forward(Forward.to(actor, action))
        |> Value.void()
        
      {:pipe, actor, action} ->
        # Transform request before piping
        transformed_request = transform_request(request)
        
        Value.of()
        |> Value.response(transformed_request)
        |> Value.state(new_state)
        |> Value.pipe(Pipe.to(actor, action))
        |> Value.void()
        
      {:local, response} ->
        # Handle locally
        Value.of(response, new_state)
    end
  end

  defp determine_target(%PriorityRequest{}, %{high_priority_actor: actor}) do
    {:forward, actor, "handle_priority"}
  end

  defp determine_target(%BatchRequest{}, _state) do
    {:pipe, "batch_processor", "process_batch"}  
  end

  defp determine_target(request, %{load: load}) when load > 0.8 do
    {:forward, "overflow_handler", "handle_overflow"}
  end

  defp determine_target(request, _state) do
    {:local, %StandardResponse{handled_by: "smart_router"}}
  end
end
```

## Error Handling in Forwards and Pipes

```elixir
defmodule MyApp.Actors.ResilientProcessor do
  use SpawnSdk.Actor,
    name: "resilient_processor",
    state_type: MyApp.Domain.ProcessorState

  action "ProcessSafely", fn %Context{state: state} = ctx, request ->
    case validate_request(request) do
      :ok ->
        # Normal processing path
        process_and_forward(ctx, request)
        
      {:error, :invalid_format} ->
        # Forward to format fixer
        Value.of()
        |> Value.forward(Forward.to("format_fixer", "fix_format"))
        |> Value.void()
        
      {:error, :rate_limited} ->
        # Delay and forward to rate limited queue
        delayed_request = %{request | retry_count: (request.retry_count || 0) + 1}
        
        Value.of()
        |> Value.response(delayed_request)
        |> Value.pipe(Pipe.to("rate_limited_queue", "queue_request"))
        |> Value.void()
        
      {:error, reason} ->
        # Handle locally with error response
        error_response = %ErrorResponse{
          error: reason,
          handled_by: "resilient_processor"
        }
        Value.of(error_response, state)
    end
  end

  defp process_and_forward(ctx, request) do
    case can_process_locally?(ctx.state) do
      true ->
        # Process locally
        result = process_request(request)
        Value.of(result, ctx.state)
        
      false ->
        # Forward to specialized processor
        processor = select_processor(request)
        
        Value.of()
        |> Value.forward(Forward.to(processor, "process"))
        |> Value.void()
    end
  end
end
```

## Dynamic Routing Patterns

### Load Balancer Actor

```elixir
defmodule MyApp.Actors.LoadBalancer do
  use SpawnSdk.Actor,
    name: "load_balancer",
    state_type: MyApp.Domain.LoadBalancerState

  action "DistributeLoad", fn %Context{state: state} = ctx, request ->
    # Select least loaded worker
    {selected_worker, updated_state} = select_worker(state)
    
    Logger.info("Routing to #{selected_worker}")
    
    Value.of()
    |> Value.state(updated_state)
    |> Value.forward(Forward.to(selected_worker, "process_work"))
    |> Value.void()
  end

  defp select_worker(state) do
    worker = state.workers
    |> Enum.min_by(& &1.current_load)
    
    updated_workers = Enum.map(state.workers, fn w ->
      if w.name == worker.name do
        %{w | current_load: w.current_load + 1}
      else
        w
      end
    end)
    
    {worker.name, %{state | workers: updated_workers}}
  end
end
```

### Circuit Breaker with Fallback

```elixir
defmodule MyApp.Actors.CircuitBreakerRouter do
  use SpawnSdk.Actor,
    name: "circuit_breaker_router",
    state_type: MyApp.Domain.CircuitBreakerState

  action "RouteWithCircuitBreaker", fn %Context{state: state} = ctx, request ->
    case state.circuit_state do
      :closed ->
        # Circuit closed - try primary service
        attempt_primary_routing(ctx, request)
        
      :half_open ->
        # Circuit half-open - try primary with monitoring
        attempt_primary_with_monitoring(ctx, request)
        
      :open ->
        # Circuit open - use fallback
        Logger.warn("Circuit breaker open, using fallback")
        
        Value.of()
        |> Value.forward(Forward.to("fallback_service", "handle_fallback"))
        |> Value.void()
    end
  end

  defp attempt_primary_routing(ctx, request) do
    primary_service = select_primary_service(request)
    
    Value.of()
    |> Value.state(ctx.state)
    |> Value.forward(Forward.to(primary_service, "process"))
    |> Value.void()
  end
end
```

## Advanced Pipe Patterns

### Data Transformation Pipeline

```elixir
defmodule MyApp.Actors.ETLPipeline do
  use SpawnSdk.Actor,
    name: "etl_pipeline", 
    stateful: false

  action "StartETL", fn _ctx, %ETLRequest{} = request ->
    # Extract phase
    extracted_data = %ExtractedData{
      source: request.source,
      raw_data: extract_data(request.source_config),
      extracted_at: DateTime.utc_now()
    }

    Value.of()
    |> Value.response(extracted_data)
    |> Value.pipe(Pipe.to("data_transformer", "transform"))
    |> Value.void()
  end
end

defmodule MyApp.Actors.DataTransformer do
  use SpawnSdk.Actor,
    name: "data_transformer",
    stateful: false

  action "Transform", fn _ctx, %ExtractedData{} = data ->
    # Transform phase
    transformed_data = %TransformedData{
      source: data.source,
      raw_data: data.raw_data,
      extracted_at: data.extracted_at,
      transformed_data: transform_data(data.raw_data),
      transformed_at: DateTime.utc_now()
    }

    Value.of()
    |> Value.response(transformed_data)
    |> Value.pipe(Pipe.to("data_loader", "load"))
    |> Value.void()
  end
end

defmodule MyApp.Actors.DataLoader do
  use SpawnSdk.Actor,
    name: "data_loader",
    stateful: false

  action "Load", fn _ctx, %TransformedData{} = data ->
    # Load phase
    load_result = load_data(data.transformed_data)
    
    final_result = %ETLResult{
      source: data.source,
      extracted_at: data.extracted_at,
      transformed_at: data.transformed_at,
      loaded_at: DateTime.utc_now(),
      records_processed: length(data.transformed_data),
      load_result: load_result
    }

    Value.of(final_result)
  end
end
```

### Conditional Pipeline Branching

```elixir
defmodule MyApp.Actors.SmartPipeline do
  use SpawnSdk.Actor,
    name: "smart_pipeline",
    stateful: false

  action "ProcessSmartly", fn _ctx, request ->
    # Analyze request to determine processing path
    analysis = analyze_request(request)
    
    processed_request = %ProcessedRequest{
      original: request,
      analysis: analysis,
      pipeline_step: 1
    }

    # Choose pipeline path based on analysis
    next_actor = case analysis.complexity do
      :simple -> "simple_processor"
      :complex -> "complex_processor"
      :ai_required -> "ai_processor"
    end

    Value.of()
    |> Value.response(processed_request)
    |> Value.pipe(Pipe.to(next_actor, "process_request"))
    |> Value.void()
  end
end
```

## Testing Forwards and Pipes

```elixir
defmodule MyApp.ForwardPipeTest do
  use ExUnit.Case

  setup do
    # Setup test actor system with all actors in the chain
    {:ok, _} = SpawnSdk.System.Supervisor.start_link(
      system: "test-system",
      actors: [
        MyApp.Actors.DataProcessor,
        MyApp.Actors.DataEnricher,
        MyApp.Actors.MockTargetActor
      ]
    )
    
    :ok
  end

  test "forward passes original payload" do
    # Test forward behavior
    {:ok, response} = SpawnSdk.invoke("request_router",
      system: "test-system",
      action: "route_payment",
      payload: %PaymentRequest{amount: 50, payment_method: :credit_card}
    )

    # Response should come from the forwarded-to actor
    assert %PaymentResponse{amount: 50} = response
    assert response.processed_by == "credit_card_processor"
  end

  test "pipe transforms response through chain" do
    # Test pipe behavior
    {:ok, response} = SpawnSdk.invoke("data_processor",
      system: "test-system", 
      action: "process_data",
      payload: %DataRequest{raw_data: "test data"}
    )

    # Response should be final transformed result
    assert %EnrichedData{} = response
    assert response.original_data == "test data"
    assert response.enriched_by == "data_enricher"
  end
end
```

## Best Practices

### When to Use Forward vs Pipe

**Use Forward when:**
- Routing requests to appropriate handlers
- Load balancing across similar services
- Delegating to specialized processors
- The target needs the original request context

**Use Pipe when:**
- Building processing pipelines
- Transforming data through multiple stages
- Each stage adds value to the previous result
- You want to compose operations

### Performance Considerations

```elixir
# Good: Minimize pipe chain depth
action "ProcessEfficiently", fn _ctx, data ->
  # Do as much processing as possible in one step
  result = comprehensive_processing(data)
  
  Value.of()
  |> Value.response(result)
  |> Value.pipe(Pipe.to("finalizer", "finalize"))
  |> Value.void()
end

# Avoid: Excessive pipe chaining
action "ProcessInefficiently", fn _ctx, data ->
  Value.of()
  |> Value.response(step1(data))
  |> Value.pipe(Pipe.to("step2_actor", "process"))  # Too many steps
  |> Value.void()  
end
```

### Error Handling

```elixir
# Always handle the case where forwarding/piping might fail
action "SafeForward", fn ctx, request ->
  case validate_target_availability("target_actor") do
    :ok ->
      Value.of()
      |> Value.forward(Forward.to("target_actor", "process"))
      |> Value.void()
      
    :unavailable ->
      # Fallback to local processing
      local_result = process_locally(request)
      Value.of(local_result, ctx.state)
  end
end
```

## Next Steps

- Learn about [broadcast patterns](broadcast.md)
- Explore [event-driven architectures](event_driven_patterns.md)
- See [performance optimization](../observability/performance.md) for pipeline tuning