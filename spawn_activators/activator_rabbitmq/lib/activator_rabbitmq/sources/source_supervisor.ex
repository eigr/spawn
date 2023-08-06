defmodule ActivatorRabbitmq.Sources.SourceSupervisor do
  use DynamicSupervisor

  def child_spec() do
    {
      PartitionSupervisor,
      child_spec: DynamicSupervisor, name: __MODULE__
    }
  end

  def start_link(_args) do
    DynamicSupervisor.start_link(
      __MODULE__,
      [
        shutdown: 120_000,
        strategy: :one_for_one
      ],
      name: __MODULE__
    )
  end

  @impl true
  def init(args), do: DynamicSupervisor.init(args)

  def start_consumer(key, config) do
    opts = make_opts(config)

    child_spec = %{
      id: ActivatorRabbitMQ.Sources.RabbitMQ,
      start: {ActivatorRabbitMQ.Sources.RabbitMQ, :start_link, [opts]},
      restart: :transient
    }

    case DynamicSupervisor.start_child(via(key), child_spec) do
      {:error, {:already_started, pid}} ->
        {:ok, pid}

      {:ok, pid} ->
        {:ok, pid}

      {:error, {:name_conflict, {{mod, name}, _f}, _registry, pid}} ->
        Logger.warning(
          "Name conflict on start Activator Consumer #{name} from PID #{inspect(pid)}."
        )

        :ignore
    end
  end

  defp via(key), do: {:via, PartitionSupervisor, {__MODULE__, get_hashkey(key)}}
  defp get_hashkey(key), do: :erlang.phash2(key)

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
