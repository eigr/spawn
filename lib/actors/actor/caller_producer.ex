defmodule Actors.Actor.CallerProducer do
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

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(state \\ []) do
    GenStage.start_link(__MODULE__, state, name: __MODULE__)
  end

  @spec get_state(ActorId.t()) :: {:ok, term()} | {:error, term()}
  def get_state(actor_id, opts \\ []) do
    if Config.get(:actors_global_backpressure_enabled) do
      GenStage.call(__MODULE__, {:enqueue, {:get_state, actor_id, opts}}, :infinity)
    else
      CallerConsumer.get_state(actor_id)
    end
  end

  @spec register(RegistrationRequest.t(), any()) ::
          {:ok, RegistrationResponse.t()} | {:error, RegistrationResponse.t()}
  def register(registration, opts \\ []) do
    if Config.get(:actors_global_backpressure_enabled) do
      GenStage.call(__MODULE__, {:enqueue, {:register, registration, opts}}, :infinity)
    else
      CallerConsumer.register(registration, opts)
    end
  end

  @spec spawn_actor(SpawnRequest.t(), any()) :: {:ok, SpawnResponse.t()}
  def spawn_actor(spawn_req, opts \\ []) do
    if Config.get(:actors_global_backpressure_enabled) do
      GenStage.call(__MODULE__, {:enqueue, {:spawn_actor, spawn_req, opts}}, :infinity)
    else
      CallerConsumer.spawn_actor(spawn_req, opts)
    end
  end

  @spec invoke(InvocationRequest.t()) :: {:ok, :async} | {:ok, term()} | {:error, term()}
  def invoke(request, opts \\ [])

  def invoke(%InvocationRequest{} = request, opts) do
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

  def enqueue(event) do
    GenStage.call(__MODULE__, {:enqueue, event})
  end

  # Server API

  def init(_state) do
    {:producer, {:queue.new(), 0}}
  end

  def handle_demand(incoming_demand, {queue, pending_demand}) do
    Logger.debug("Consumer pull demand of: #{incoming_demand} elements.")
    dispatch_events(queue, incoming_demand + pending_demand, [])
  end

  def handle_call({:enqueue, event}, from, {queue, pending_demand}) do
    queue = :queue.in({from, event}, queue)
    dispatch_events(queue, pending_demand, [])
  end

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
