defmodule ActivatorRabbitMQ.Application do
  @moduledoc false

  use Application
  require Logger

  alias Actors.Config.Vapor, as: Config
  alias ActivatorRabbitmq.Supervisor, as: RabbitMQConsumerSupervisor

  @impl true
  def start(_type, _args) do
    config = Config.load(__MODULE__)

    children = [
      {RabbitMQConsumerSupervisor, config}
    ]

    opts = [strategy: :one_for_one, name: ActivatorRabbitMQ.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
