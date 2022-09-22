defmodule ActivatorRabbitMQ.Application do
  @moduledoc false

  use Application
  require Logger

  alias Actors.Config.Vapor, as: Config

  import Activator, only: [get_http_port: 1]

  @impl true
  def start(_type, _args) do
    config = Config.load(__MODULE__)

    children =
      [
        {Bandit,
         plug: ActivatorRabbitMQ.Router, scheme: :http, options: [port: get_http_port(config)]},
        Spawn.Cluster.Supervisor.child_spec(config),
        {ActivatorRabbitMQ.Sources.RabbitMQ, make_opts(config)}
      ] ++
        if Mix.env() == :test,
          do: [],
          else: [Actors.Supervisors.EntitySupervisor.child_spec(config)]

    opts = [strategy: :one_for_one, name: ActivatorRabbitMQ.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp make_opts(_config) do
    [
      encoder: Activator.Encoder.CloudEvent,
      actor_system: "spawn-system",
      actor_concurrency: 1,
      username: "guest",
      password: "guest",
      source_queue: "test",
      source_concurrency: 1,
      prefetch_count: 50,
      provider_host: "localhost",
      provider_port: 5672,
      provider_url: nil,
      use_rate_limiting: true,
      rate_limiting_interval: 1,
      rate_limiting_allowed_messages: 100,
      targets: [
        # %{actor: "joe", command: "setLanguage"},
        %{actor: "robert", command: "setLanguage"}
      ]
    ]
  end
end
