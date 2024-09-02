defmodule StatestoreController.Supervisor do
  @moduledoc false

  import Statestores.Util,
    only: [load_lookup_adapter: 0, load_snapshot_adapter: 0]

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def child_spec(args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [args]}
    }
  end

  @impl true
  def init(args) do
    lookup_adapter = load_lookup_adapter()
    snapshot_adapter = load_snapshot_adapter()
    Statestores.Migrator.migrate(snapshot_adapter)
    Statestores.Migrator.migrate(lookup_adapter)

    children =
      [
        Statestores.Vault,
        snapshot_adapter,
        lookup_adapter
      ]
      |> maybe_add_cdc(snapshot_adapter, args)

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp maybe_add_cdc(children, snapshot_adapter, args)
       when is_atom(snapshot_adapter) and
              snapshot_adapter in [Statestores.Adapters.PostgresSnapshotAdapter] do
    children ++ [{StatestoreController.CDC.CdcSupervisor, [args]}]
  end

  defp maybe_add_cdc(_children, _snapshot_adapter, _args), do: nil
end
