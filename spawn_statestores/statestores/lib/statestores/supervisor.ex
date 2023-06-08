defmodule Statestores.Supervisor do
  @moduledoc false
  use Supervisor

  import Statestores.Util, only: [load_lookup_adapter: 0, load_snapshot_adapter: 0]

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
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
    Statestores.Config.load()
    Statestores.Migrator.migrate(snapshot_adapter)
    Statestores.Migrator.migrate(lookup_adapter)

    children = [
      Statestores.Vault,
      snapshot_adapter,
      lookup_adapter
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
