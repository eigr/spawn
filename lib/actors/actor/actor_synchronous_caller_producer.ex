defmodule Actors.Actor.ActorSynchronousCallerProducer do
  use GenStage

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(state \\ []) do
    GenStage.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(_state) do
    {:producer, {:queue.new(), 0}}
  end

  def handle_call({:enqueue, event}, from, {queue, pending_demand}) do
    queue = :queue.in({from, event}, queue)
    dispatch_events(queue, pending_demand, [])
  end

  def handle_demand(incoming_demand, {queue, pending_demand}) do
    dispatch_events(queue, incoming_demand + pending_demand, [])
  end

  def get_state(actor_id, opts \\ []) do
    GenStage.call(__MODULE__, {:enqueue, {:get_state, actor_id, opts}})
  end

  def register(registration, opts \\ []) do
    GenStage.call(__MODULE__, {:enqueue, {:register, registration, opts}})
  end

  def spawn_actor(spawn_req, opts \\ []) do
    GenStage.call(__MODULE__, {:enqueue, {:spawn_actor, spawn_req, opts}})
  end

  def invoke(request, opts \\ []) do
    GenStage.call(__MODULE__, {:enqueue, {:invoke, request, opts}})
  end

  def enqueue(event) do
    GenStage.call(__MODULE__, {:enqueue, event})
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
