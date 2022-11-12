defmodule SpawnSdkExample.Subscriber do
  @moduledoc """
  This module exemplifies how to listen for pubsub events that were emitted by actors but that will be treated not by actors but as normal pubsub events.
  This is particularly useful for integrations between Spawn and Phoenix LiveView.
  """
  use GenServer
  require Logger

  alias Phoenix.PubSub

  @impl true
  def init(state) do
    PubSub.subscribe(:actor_channel, "external.channel")
    {:ok, state}
  end

  @impl true
  def handle_info({:receive, payload}, state) do
    Logger.info("Received pubsub event #{inspect(payload)}")
    {:noreply, state}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end
end
