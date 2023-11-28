defmodule Actors.Actor.CallerProducer do
  @moduledoc """
  # Actors.Actor.CallerProducer
  This module defines a GenStage producer responsible for managing actor-related
  operations such as retrieving actor state, actor registration, actor spawning, and actor invocation.

  ## Client API

  The client API provides functions for interacting with actors.
  These functions can be used to initiate operations such as getting actor state,
  registering actors, spawning new actors, and invoking actors.

  ### Functions

  - [`start_link/1`](#start_link-1): Starts the CallerProducer process.
  - [`get_state/2`](#get_state-2): Retrieves the state of a specified actor.
  - [`register/2`](#register-2): Registers an actor with the specified registration request.
  - [`spawn_actor/2`](#spawn_actor-2): Spawns an actor based on the specified spawn request.
  - [`invoke/2`](#invoke-2): Invokes an actor with the specified invocation request.
  - [`enqueue/1`](#enqueue-1): Enqueues an event for processing.

  ## Server API

  The server API includes functions that handle the GenStage behavior.
  These functions manage the state and processing of events.

  ### Functions

  - [`init/1`](#init-1): Initializes the GenStage process.
  - [`handle_demand/2`](#handle_demand-2): Handles demand requests from consumers.
  - [`handle_call/3`](#handle_call-3): Handles call requests from consumers.
  - [`handle_cast/2`](#handle_cast-2): Handles cast requests from consumers.

  ## Usage
  To interact with this module, use the client API functions provided.
  These functions handle backpressure if enabled in the configuration.

  """
  use GenStage
  require Logger

  alias Actors.Actor.CallerConsumer
  alias Actors.Config.PersistentTermConfig, as: Config
  alias Eigr.Functions.Protocol.Actors.ActorId

  alias Eigr.Functions.Protocol.{
    InvocationRequest,
    RegistrationRequest,
    RegistrationResponse,
    SpawnRequest,
    SpawnResponse
  }

  # Client API

  @doc """
  Starts the CallerProducer process.

  ## Parameters

  - `state` (any): Initial state for the process.

  ## Returns

  - `:ignore`: If the process is already running.
  - `{:error, reason}`: If an error occurs during process initialization.
  - `{:ok, pid}`: If the process starts successfully.

  """
  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(state \\ []) do
    GenStage.start_link(__MODULE__, state, name: __MODULE__)
  end

  @doc """
  Retrieves the state of a specified actor.

  ## Parameters

  - `actor_id` (ActorId.t()): The ID of the actor.
  - `opts` (any): Additional options.

  ## Returns

  - `{:ok, state}`: If the state is successfully retrieved.
  - `{:error, reason}`: If an error occurs during the operation.

  """
  @spec get_state(ActorId.t()) :: {:ok, term()} | {:error, term()}
  def get_state(actor_id, opts \\ []) do
    if Config.get(:actors_global_backpressure_enabled) do
      GenStage.call(__MODULE__, {:enqueue, {:get_state, actor_id, opts}}, :infinity)
    else
      CallerConsumer.get_state(actor_id)
    end
  end

  @doc """
  Registers an actor with the specified registration request.

  ## Parameters

  - `registration` (RegistrationRequest.t()): The registration request.
  - `opts` (any): Additional options.

  ## Returns

  - `{:ok, response}`: If the actor is successfully registered.
  - `{:error, response}`: If an error occurs during the registration.

  """
  @spec register(RegistrationRequest.t(), any()) ::
          {:ok, RegistrationResponse.t()} | {:error, RegistrationResponse.t()}
  def register(registration, opts \\ []) do
    if Config.get(:actors_global_backpressure_enabled) do
      GenStage.call(__MODULE__, {:enqueue, {:register, registration, opts}}, :infinity)
    else
      CallerConsumer.register(registration, opts)
    end
  end

  @doc """
  Spawns an actor based on the specified spawn request.

  ## Parameters

  - `spawn_req` (SpawnRequest.t()): The spawn request.
  - `opts` (any): Additional options.

  ## Returns

  - `{:ok, response}`: If the actor is successfully spawned.
  - `{:error, response}`: If an error occurs during the spawning.

  """
  @spec spawn_actor(SpawnRequest.t(), any()) :: {:ok, SpawnResponse.t()}
  def spawn_actor(spawn_req, opts \\ []) do
    if Config.get(:actors_global_backpressure_enabled) do
      GenStage.call(__MODULE__, {:enqueue, {:spawn_actor, spawn_req, opts}}, :infinity)
    else
      CallerConsumer.spawn_actor(spawn_req, opts)
    end
  end

  @doc """
  Invokes an actor with the specified invocation request.

  ## Parameters

  - `request` (InvocationRequest.t()): The invocation request.
  - `opts` (any): Additional options.

  ## Returns

  - `{:ok, :async}`: If the invocation is asynchronous.
  - `{:ok, result}`: If the invocation is successful.
  - `{:error, reason}`: If an error occurs during the invocation.

  """
  @spec invoke(InvocationRequest.t()) :: {:ok, :async} | {:ok, term()} | {:error, term()}
  def invoke(request, opts \\ [])

  def invoke(%InvocationRequest{} = request, opts) do
    if Sidecar.GracefulShutdown.get_status() in [:draining, :stopping] do
      raise ErlangError, "The ActorHost is shutting down and can no longer receive invocations"
    end

    if Config.get(:actors_global_backpressure_enabled) do
      if request.async do
        GenStage.cast(__MODULE__, {:enqueue, {:invoke, request, opts}})
        {:ok, :async}
      else
        GenStage.call(__MODULE__, {:enqueue, {:invoke, request, opts}}, :infinity)
      end
    else
      if request.register_ref != "" and not is_nil(request.register_ref) do
        spawn_req = %SpawnRequest{
          actors: [%ActorId{request.actor.id | parent: request.register_ref}]
        }

        spawn_actor(spawn_req, opts)
      end

      CallerConsumer.invoke_with_span(request, opts)
    end
  end

  @doc """
  Enqueues an event for processing.

  ## Parameters

  - `event` (any): The event to be enqueued.

  """
  def enqueue(event) do
    GenStage.call(__MODULE__, {:enqueue, event})
  end

  # Server API

  @doc false
  def init(_state) do
    {:producer, {:queue.new(), 0}}
  end

  @doc false
  def handle_demand(incoming_demand, {queue, pending_demand}) do
    Logger.debug("Consumer pull demand of: #{incoming_demand} elements.")
    dispatch_events(queue, incoming_demand + pending_demand, [])
  end

  @doc false
  def handle_call({:enqueue, event}, from, {queue, pending_demand}) do
    queue = :queue.in({from, event}, queue)
    dispatch_events(queue, pending_demand, [])
  end

  @doc false
  def handle_cast({:enqueue, event}, {queue, pending_demand}) do
    queue = :queue.in({:fake_from, event}, queue)
    dispatch_events(queue, pending_demand, [])
  end

  defp dispatch_events(queue, 0, events) do
    {:noreply, Enum.reverse(events), {queue, 0}}
  end

  defp dispatch_events(queue, demand, events) do
    case :queue.out(queue) do
      {{:value, {from, event}}, queue} ->
        dispatch_events(queue, demand - 1, [{from, event} | events])

      {:empty, queue} ->
        {:noreply, Enum.reverse(events), {queue, demand}}
    end
  end
end
