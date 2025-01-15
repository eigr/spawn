defmodule Statestores.Supervisor do
  @moduledoc false
  use Supervisor

  @shutdown_timeout_ms 330_000

  import Statestores.Util,
    only: [
      load_lookup_adapter: 0,
      load_snapshot_adapter: 0,
      load_projection_adapter: 0,
      supervisor_process_logger: 1
    ]

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__, shutdown: @shutdown_timeout_ms)
  end

  def child_spec() do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [[]]}
    }
  end

  @impl true
  def init(_args) do
    lookup_adapter = load_lookup_adapter()
    snapshot_adapter = load_snapshot_adapter()
    projection_adapter = load_projection_adapter()

    case System.get_env("MIX_ENV") do
      env when env in ["dev", "test"] ->
        Statestores.Migrator.migrate(snapshot_adapter)
        Statestores.Migrator.migrate(lookup_adapter)

      _ ->
        # TODO: migrate via job in production (future release)
        Statestores.Migrator.migrate(snapshot_adapter)
        Statestores.Migrator.migrate(lookup_adapter)
    end

    children =
      [
        supervisor_process_logger(__MODULE__),
        Statestores.Vault,
        snapshot_adapter,
        lookup_adapter,
        projection_adapter
      ]
      |> maybe_add_native_children(snapshot_adapter)

    Supervisor.init(children, strategy: :one_for_one)
  end

  def maybe_add_native_children(children, Statestores.Adapters.NativeSnapshotAdapter) do
    children ++ Kernel.apply(Statestores.Adapters.Native.Children, :get_children, [])
  end

  def maybe_add_native_children(children, _), do: children
end
