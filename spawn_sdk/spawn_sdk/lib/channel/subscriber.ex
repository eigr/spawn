defmodule SpawnSdk.Channel.Subscriber do
  @moduledoc """
  `Subscriber` is a helper module to subscribe Phoenix.PubSub channels
  """

  alias Phoenix.PubSub

  @type channel :: String.t()

  @type opts :: Keyword.t()

  @default_pubsub_group :actor_channel

  @pubsub Application.compile_env(:spawn, :pubsub_group, @default_pubsub_group)

  @spec subscribe(channel(), opts()) :: :ok | {:error, term()}
  def subscribe(channel, opts \\ [])

  def subscribe(channel, _opts) do
    PubSub.subscribe(@pubsub, channel)
  end

  @spec unsubscribe(channel()) :: :ok
  def unsubscribe(channel) do
    PubSub.unsubscribe(@pubsub, channel)
  end
end
