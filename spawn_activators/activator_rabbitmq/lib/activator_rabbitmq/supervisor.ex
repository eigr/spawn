defmodule ActivatorRabbitmq.Supervisor do
  use Supervisor

  import Activator, only: [get_http_port: 1]

  @impl true
  def init(config) do
    children = [
      {Bandit,
       plug: ActivatorRabbitMQ.Router, scheme: :http, options: [port: get_http_port(config)]},
      {Sidecar.Supervisor, config},
      {ActivatorRabbitMQ.Sources.RabbitMQ, make_opts(config)}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def start_link(config) do
    Supervisor.start_link(
      __MODULE__,
      config,
      shutdown: 120_000,
      strategy: :one_for_one
    )
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
