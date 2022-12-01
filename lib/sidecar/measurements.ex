defmodule Sidecar.Measurements do
  @moduledoc false

  def stats(config) do
    otp_release = :erlang.system_info(:otp_release)
    multi_scheduling = :erlang.system_info(:multi_scheduling)
    threads = :erlang.system_info(:threads)
    smp_support = :erlang.system_info(:smp_support)

    dirty_cpu_schedulers = :erlang.system_info(:dirty_cpu_schedulers)
    dirty_cpu_schedulers_online = :erlang.system_info(:dirty_cpu_schedulers_online)
    dist_buf_busy_limit = :erlang.system_info(:dist_buf_busy_limit)
    process_count = :erlang.system_info(:process_count)
    schedulers = :erlang.system_info(:schedulers)
    schedulers_online = :erlang.system_info(:schedulers_online)
    thread_pool_size = :erlang.system_info(:thread_pool_size)

    :telemetry.execute(
      [:vm, :system_info],
      %{
        dirty_cpu_schedulers: dirty_cpu_schedulers,
        dirty_cpu_schedulers_online: dirty_cpu_schedulers_online,
        dist_buf_busy_limit: dist_buf_busy_limit,
        process_count: process_count,
        schedulers: schedulers,
        schedulers_online: schedulers_online,
        thread_pool_size: thread_pool_size
      },
      %{
        host_ip: config.node_host_interface,
        proxy_ip: config.proxy_host_interface,
        otp_release: "#{otp_release}",
        smp_support: smp_support,
        multi_scheduling: multi_scheduling,
        threads: threads
      }
    )
  end

  def dispatch_invoke_duration(system, actor_name, action, duration) do
    :telemetry.execute(
      [:spawn, :invoke, :stop],
      %{duration: duration},
      %{system: system, name: actor_name, action: action}
    )
  end

  def dispatch_actor_inflights(system, actor_name, value) do
    :telemetry.execute([:spawn, :actor, :inflight_messages], %{messages: value}, %{
      system: system,
      name: actor_name
    })
  end
end
