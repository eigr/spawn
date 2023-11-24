defmodule Actors.Actor.Pubsub do
  use GenServer

  require Logger

  alias Eigr.Functions.Protocol.InvocationRequest
  alias Eigr.Functions.Protocol.Actors.ActorSystem
  alias Eigr.Functions.Protocol.Actors.Actor
  alias Eigr.Functions.Protocol.Actors.ActorId

  @default_pubsub_group :actor_channel
  @pubsub Application.compile_env(:spawn, :pubsub_group, @default_pubsub_group)

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def publish(topic, payload, request) do
    Phoenix.PubSub.broadcast(
      @pubsub,
      topic,
      {:receive, payload, request.actor},
      Actors.Actor.PubsubDispatcher
    )
  end

  @doc """
  Subscribes a specific actor to a topic
  """
  def subscribe(topic, actor_name, system, action_handler \\ nil) do
    GenServer.cast(__MODULE__, {:subscribe, topic, actor_name, system, action_handler})
  end

  @impl true
  def init(_opts) do
    {:ok, nil}
  end

  @impl true
  def handle_cast({:subscribe, topic, actor_name, system, action_handler}, state) do
    metadata = %{actor_name: actor_name, system: system, action: action_handler}

    Phoenix.PubSub.subscribe(@pubsub, topic, metadata: metadata)

    {:noreply, state}
  end

  @impl true
  def handle_info({{:receive, payload, caller}, metadata}, state) do
    action =
      Map.get(metadata, :action)
      |> case do
        nil -> "receive"
        "" -> "receive"
        action -> action
      end

    actor_name = Map.get(metadata, :actor_name)
    system = Map.get(metadata, :system)

    Logger.debug(
      "Actor [#{actor_name}] Received Broadcast Event to perform Action [#{action}] from caller #{inspect(caller)}"
    )

    invocation = %InvocationRequest{
      system: %ActorSystem{name: system},
      actor: %Actor{
        id: %ActorId{name: actor_name, system: system}
      },
      action_name: action,
      payload: payload,
      caller: caller,
      async: true
    }

    {:ok, :async} = Actors.invoke(invocation)

    {:noreply, state}
  end
end
