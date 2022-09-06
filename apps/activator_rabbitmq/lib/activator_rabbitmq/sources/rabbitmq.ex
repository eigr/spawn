defmodule ActivatorRabbitMQ.Sources.RabbitMQ do
  @moduledoc """
  RabbitMQ Broadway Producer
  """
  use Broadway
  require Logger

  alias Activator.Eventing.Dispatcher

  alias Broadway.Message

  def start_link(opts), do: start_source(opts)

  defp start_source(opts) do
    actor_concurrency = Keyword.get(opts, :actor_concurrency, 1)
    actor_system = Keyword.fetch!(opts, :actor_system)
    target_actors = Keyword.fetch!(opts, :targets)

    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      context: [
        dispatcher: Activator.Eventing.Dispatcher,
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
    pasword = Keyword.fetch!(opts, :password)
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
           password: pasword
         ],
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

  @impl true
  def handle_message(_, message, context) do
    system = Keyword.fetch!(context, :system)
    actors = Keyword.fetch!(context, :targets)

    message
    |> Message.update_data(fn data ->
      Logger.info("Received message #{inspect(data)}")

      # data2 = binary_to_string(data)
      # data = if is_binary(data), do: binary_to_string(data), else: data

      Dispatcher.dispatch(data, system, actors)

      # with {:ok, event} <- Cloudevents.from_json(data2) do
      #   Dispatcher.dispatch(event, system, actors)
      # else
      #   error ->
      #     Logger.warn("Failed to parse the message #{inspect(data2)}. Error #{inspect(error)}")
      #     # raise "Failed to parse the message #{inspect(data2)}"
      # end
    end)
  rescue
    e ->
      Logger.error(Exception.format(:error, e, __STACKTRACE__))
      # reraise e, __STACKTRACE__
  end

  def binary_to_string(binary) do
    binary
    |> String.replace("\\", "")
    # |> Jason.decode!()
    # |> String.replace("\\", "")
    # |> String.replace("\\", "")
    |> IO.inspect(label: "String result")
  end

  def caesar(list, n) do
    Enum.map(
      list,
      &(perform_addition(&1, n)
        |> to_charlist
        |> to_string)
    )
  end

  defp perform_addition(char_val, n) when char_val < 122 do
    char_val + n
  end

  defp perform_addition(_, n) do
    97 + n
  end
end
