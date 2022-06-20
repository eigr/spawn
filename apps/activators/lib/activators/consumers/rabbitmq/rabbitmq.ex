defmodule Activators.Consumers.RabbitMQ do
  @moduledoc """
  RabbitMQ Broadway Producer
  """
  use Broadway

  alias Broadway.Message

  def start_link(opts) do
    dispatcher = Keyword.fetch!(opts, :dispatcher_module)
    queue = Keyword.fetch!(opts, :source_queue)
    username = Keyword.fetch!(opts, :username)
    pasword = Keyword.fetch!(opts, :password)
    source_concurrency = Keyword.fetch!(opts, :source_concurrency)
    actor_concurrency = Keyword.fetch!(opts, :actor_concurrency)

    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      context: [
        dispatcher: dispatcher
      ],
      procucer: [
        module:
          {BroadwayRabbitMQ.Producer,
           queue: queue,
           connection: [
             username: username,
             password: pasword
           ],
           qos: [
             prefetch_count: 50
           ]},
        concurrency: source_concurrency
      ],
      processors: [
        default: [
          concurrency: actor_concurrency
        ]
      ]
    )
  end

  @impl true
  def handle_message(_, message, context) do
    dispatcher = Keyword.fetch!(context, :dispatcher)

    message
    |> Message.update_data(fn data ->
      case Cloudevents.from_json(data) do
        {:ok, event} -> event
        {:error, _error} -> %{data: nil}
      end
    end)
    |> dispatcher.dispatch()
  end
end
