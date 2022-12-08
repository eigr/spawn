defmodule Sidecar.Supervisor do
  @moduledoc false
  use Supervisor

  @impl true
  def init(config) do
    children =
      [
        {Sidecar.GracefulShutdown, []},
        {Sidecar.ProcessSupervisor, config}
      ]
      |> Enum.reject(&is_nil/1)

    Supervisor.init(children, strategy: :one_for_one)
  end

  def start_link(config) do
    Supervisor.start_link(
      __MODULE__,
      config,
      name: __MODULE__,
      shutdown: 120_000,
      strategy: :one_for_one
    )
  end
end
