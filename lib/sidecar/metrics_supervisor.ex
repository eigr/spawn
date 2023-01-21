defmodule Sidecar.MetricsSupervisor do
  @moduledoc false
  use Supervisor
  import Telemetry.Metrics

  def start_link(config) do
    Supervisor.start_link(__MODULE__, config, name: __MODULE__)
  end

  def init(config) do
    children = if config.proxy_disable_metrics, do: [], else: get_metrics_supervisor_tree(config)

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp get_metrics_supervisor_tree(config) do
    if config.proxy_console_metrics do
      [
        {:telemetry_poller, measurements: periodic_measurements(config)},
        {TelemetryMetricsPrometheus.Core, name: :spawm_metrics, metrics: metrics()},
        {Telemetry.Metrics.ConsoleReporter, metrics: metrics()}
      ]
    else
      [
        {:telemetry_poller, measurements: periodic_measurements(config)},
        {TelemetryMetricsPrometheus.Core, name: :spawm_metrics, metrics: metrics()}
      ]
    end
  end

  defp metrics do
    [
      # VM Metrics
      last_value("vm.system_info.process_count"),
      last_value("vm.system_info.schedulers"),
      last_value("vm.system_info.schedulers_online"),
      last_value("vm.system_info.dirty_cpu_schedulers"),
      last_value("vm.system_info.dirty_cpu_schedulers_online"),
      last_value("vm.system_info.thread_pool_size"),
      last_value("vm.system_info.dist_buf_busy_limit", unit: :byte),
      last_value("vm.memory.total", unit: :byte),
      last_value("vm.total_run_queue_lengths.total"),
      last_value("vm.total_run_queue_lengths.cpu"),
      last_value("vm.total_run_queue_lengths.io"),

      # Actor Metrics
      last_value("spawn.actor.memory", unit: :byte),
      last_value("spawn.actor.message_queue_len"),
      last_value("spawn.actor.inflight_messages.messages"),
      counter("spawn.invoke.stop.duration"),
      summary("spawn.invoke.stop.duration", unit: {:native, :millisecond})
    ]
  end

  defp periodic_measurements(config) do
    [
      {:process_info,
       event: [:spawn, :actor], name: Actors.Actor.Entity, keys: [:message_queue_len, :memory]},
      {Sidecar.Measurements, :stats, [config]}
    ]
  end
end
