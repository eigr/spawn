defmodule ActivatorRabbitmq.Supervisor do
  use Supervisor

  import Activator, only: [get_http_port: 1, read_config_from_file: 1]
  import Spawn.Utils.Common, only: [supervisor_process_logger: 1]

  @impl true
  def init(opts) do
    config_file_path = Keyword.get(opts, :config_file_path, "/opt/activator/data/config.json")

    listeners =
      case read_config_from_file(config_file_path) do
        {:ok, configs} when is_list(configs) ->
          Enum.map(configs, fn cfg -> build_listener(cfg, opts) end)

        {:error, reason} ->
          Logger.warning(
            "Unable to initialize any listener. Failed to read configuration. Details #{inspect(reason)}"
          )

          raise ErlangError,
                "Unable to initialize any listener. Failed to read configuration. Details #{inspect(reason)}"
      end

    children =
      [
        supervisor_process_logger(__MODULE__),
        Activator.Supervisor.child_spec(opts),
        {Bandit, plug: ActivatorRabbitMQ.Router, scheme: :http, port: get_http_port()}
      ] ++ listeners

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp build_listener(cfg, opts) do
    config = Map.merge(cfg, Enum.into(opts, %{}))
    ActivatorRabbitmq.Sources.SourceSupervisor.child_spec(config)
  end

  def start_link(opts) do
    Supervisor.start_link(
      __MODULE__,
      opts,
      shutdown: 120_000,
      strategy: :one_for_one
    )
  end
end
