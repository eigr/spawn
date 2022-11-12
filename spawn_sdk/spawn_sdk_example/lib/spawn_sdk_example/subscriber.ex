defmodule SpawnSdkExample.Subscriber do
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

  def handle_info(any, state) do
    Logger.info("Unknow event #{inspect(any)}")
    {:noreply, state}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end
end
