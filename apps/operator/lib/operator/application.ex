defmodule Operator.Application do
  @moduledoc false
  use Application

  require Logger

  @port 9090

  @impl true
  def start(_type, _args) do
    Logger.info("Starting Eigr Functions Controller...")

    attach_logger()

    MetricsEndpoint.Exporter.setup()
    MetricsEndpoint.PrometheusPipeline.setup()

    children = [
      {Bandit, plug: Operator.Router, scheme: :http, options: [port: @port]}
    ]

    opts = [strategy: :one_for_one, name: Operator.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @spec attach_logger() :: :ok
  defp attach_logger() do
    bonny_events = Bonny.Sys.Event.events()
    # eo_events = EvictionOperator.Event.events()
    events = bonny_events
    # ++ eo_events

    :telemetry.attach_many("eigr-functions-controller-logger", events, &log_handler/4, [])
    :ok
  end

  @doc false
  @spec log_handler(keyword, map | integer, map, list) :: :ok
  def log_handler(event, measurements, metadata, _opts) do
    event_name = Enum.join(event, ".")

    level =
      case Regex.match?(~r/fail|error/, event_name) do
        true ->
          :error

        _ ->
          case Regex.match?(~r/^bonny\./, event_name) do
            true -> :debug
            _ -> :info
          end
      end

    Logger.log(level, "[#{event_name}] #{inspect(measurements)} #{inspect(metadata)}")
  end
end
