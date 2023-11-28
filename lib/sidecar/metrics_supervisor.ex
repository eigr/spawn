defmodule Sidecar.MetricsSupervisor do
  @moduledoc false
  use Supervisor
  import Telemetry.Metrics
  import Spawn.Utils.Common, only: [supervisor_process_logger: 1]

  alias Actors.Config.PersistentTermConfig, as: Config

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    children =
      if Config.get(:proxy_disable_metrics),
        do: [supervisor_process_logger(__MODULE__)],
        else: [supervisor_process_logger(__MODULE__)] ++ get_metrics_supervisor_tree(opts)

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp get_metrics_supervisor_tree(opts) do
    if Config.get(:proxy_console_metrics) do
      [
        {:telemetry_poller, measurements: periodic_measurements(opts)},
        {TelemetryMetricsPrometheus.Core, name: :spawm_metrics, metrics: metrics()},
        {Telemetry.Metrics.ConsoleReporter, metrics: metrics()}
      ]
    else
      [
        {:telemetry_poller, measurements: periodic_measurements(opts)},
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

  defp periodic_measurements(opts) do
    [
      {:process_info,
       event: [:spawn, :actor], name: Actors.Actor.Entity, keys: [:message_queue_len, :memory]},
      {Sidecar.Measurements, :stats, [opts]}
    ]
  end
end
