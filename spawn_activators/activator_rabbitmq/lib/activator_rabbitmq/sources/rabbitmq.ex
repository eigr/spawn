defmodule ActivatorRabbitMQ.Sources.RabbitMQ do
  @moduledoc """
  RabbitMQ Broadway Producer
  """
  use Broadway
  require Logger

  alias Activator.Dispatcher.DefaultDispatcher, as: Dispatcher

  alias Broadway.Message

  @spec start_link(keyword) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts), do: start_source(opts)

  @impl true
  def handle_message(_, message, context) do
    encoder = Keyword.fetch!(context, :encoder)
    system = Keyword.fetch!(context, :system)
    actors = Keyword.fetch!(context, :targets)

    message
    |> Message.update_data(fn data ->
      Logger.debug("Received message #{inspect(data)}")
      Dispatcher.dispatch(encoder, data, system, actors)
    end)
  rescue
    e ->
      Logger.error(Exception.format(:error, e, __STACKTRACE__))
      # reraise e, __STACKTRACE__
  end

  defp start_source(opts) do
    encoder = Keyword.get(opts, :encoder, Activator.Encoder.Base64)
    actor_concurrency = Keyword.get(opts, :actor_concurrency, 1)
    actor_system = Keyword.fetch!(opts, :actor_system)
    target_actors = Keyword.fetch!(opts, :targets)

    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      context: [
        encoder: encoder,
        system: actor_system,
        targets: target_actors
      ],
      producer: get_producer_settings(opts),
      processors: [
        default: [
          concurrency: actor_concurrency
        ]
      ]
    )
  end

  defp get_producer_settings(opts) do
    queue = Keyword.fetch!(opts, :source_queue)
    username = Keyword.fetch!(opts, :username)
    password = Keyword.fetch!(opts, :password)
    provider_host = Keyword.get(opts, :provider_host, "localhost")
    provider_port = Keyword.get(opts, :provider_port, 5672)
    source_concurrency = Keyword.get(opts, :source_concurrency, 1)
    qos_prefetch_count = Keyword.get(opts, :prefetch_count, 50)

    producer = [
      module:
        {BroadwayRabbitMQ.Producer,
         queue: queue,
         connection: [
           host: provider_host,
           port: provider_port,
           username: username,
           password: password
         ],
         on_failure: :reject_and_requeue_once,
         qos: [
           prefetch_count: qos_prefetch_count
         ]},
      concurrency: source_concurrency
    ]

    case Keyword.get(producer, :use_rate_limiting, false) do
      true ->
        interval = Keyword.get(opts, :rate_limiting_interval, 1_000)
        allowed_messages = Keyword.fetch!(opts, :rate_limiting_allowed_messages)

        rate_limiting = [
          interval: interval,
          allowed_messages: allowed_messages
        ]

        Keyword.merge(producer, rate_limiting)

      false ->
        producer
    end
  end
end
