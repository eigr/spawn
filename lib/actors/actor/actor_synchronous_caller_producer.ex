defmodule Actors.Actor.ActorSynchronousCallerProducer do
  use GenStage
  require Logger

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
    GenStage.call(__MODULE__, {:enqueue, {:get_state, actor_id, opts}}, :infinity)
  end

  @spec register(RegistrationRequest.t(), any()) ::
          {:ok, RegistrationResponse.t()} | {:error, RegistrationResponse.t()}
  def register(registration, opts \\ []) do
    GenStage.call(__MODULE__, {:enqueue, {:register, registration, opts}}, :infinity)
  end

  @spec spawn_actor(SpawnRequest.t(), any()) :: {:ok, SpawnResponse.t()}
  def spawn_actor(spawn_req, opts \\ []) do
    GenStage.call(__MODULE__, {:enqueue, {:spawn_actor, spawn_req, opts}}, :infinity)
  end

  @spec invoke(InvocationRequest.t()) :: {:ok, :async} | {:ok, term()} | {:error, term()}
  def invoke(request, opts \\ []) do
    GenStage.call(__MODULE__, {:enqueue, {:invoke, request, opts}}, :infinity)
  end

  def enqueue(event) do
    GenStage.call(__MODULE__, {:enqueue, event})
  end

  # Server API

  def init(_state) do
    {:producer, {:queue.new(), 0}}
  end

  def handle_call({:enqueue, event}, from, {queue, pending_demand}) do
    queue = :queue.in({from, event}, queue)
    dispatch_events(queue, pending_demand, [])
  end

  def handle_demand(incoming_demand, {queue, pending_demand}) do
    Logger.debug("Producer Handle Demand: #{incoming_demand}.")
    dispatch_events(queue, incoming_demand + pending_demand, [])
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
