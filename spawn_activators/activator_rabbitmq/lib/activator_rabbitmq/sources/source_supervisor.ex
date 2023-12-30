defmodule ActivatorRabbitmq.Sources.SourceSupervisor do
  use Supervisor

  def child_spec(config) do
    name = Map.get(config, :name, "rabbitmq-activator-#{inspect(:rand.uniform(1000))}")

    %{
      id: Atom.to_string(name),
      start: {__MODULE__, :start_link, [config]}
    }
  end

  def start_link(config) do
    name = Map.get(config, :name, "rabbitmq-activator-#{inspect(:rand.uniform(1000))}")
    Supervisor.start_link(__MODULE__, config, name: Atom.to_string(name))
  end

  @impl true
  def init(config) do
    children = [
      {ActivatorRabbitMQ.Sources.RabbitMQ, [config]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
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
        # %{actor: "joe", action: "setLanguage"},
        %{actor: "robert", action: "setLanguage"}
      ]
    ]
  end
end
