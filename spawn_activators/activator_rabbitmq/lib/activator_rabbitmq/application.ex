defmodule ActivatorRabbitMQ.Application do
  @moduledoc false

  use Application
  require Logger

  Actors.Config.PersistentTermConfig as: Config
  alias ActivatorRabbitmq.Supervisor, as: RabbitMQConsumerSupervisor

  @impl true
  def start(_type, _args) do
    Config.load()

    children = [
      {RabbitMQConsumerSupervisor, []}
    ]

    opts = [strategy: :one_for_one, name: ActivatorRabbitMQ.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
