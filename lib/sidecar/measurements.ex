defmodule Sidecar.Measurements do
  @moduledoc false

  def dispatch_system_info() do
    :telemetry.execute(
      [:vm, :system_info, :process_count],
      %{last_value: :erlang.system_info(:process_count)},
      %{}
    )
  end

  def emit_invoke_duration(system, actor_name, duration) do
    :telemetry.execute([:spawn, :invoke, :stop], %{system: system, actor: actor_name, duration: duration})
  end

  def emit_actor_inflights(system, actor_name, value) do
    :telemetry.execute([:spawn, :actor, :inflights], %{value: value}, %{system: system, actor: actor_name})
  end
end
