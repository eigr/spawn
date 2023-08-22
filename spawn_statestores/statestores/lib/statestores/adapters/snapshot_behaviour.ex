defmodule Statestores.Adapters.SnapshotBehaviour do
  @moduledoc """
  Defines the default behavior for each Statestore Provider.
  """
  alias Statestores.Schemas.Snapshot

  @type id :: String.t()

  @type revision :: integer()

  @type snapshot :: Snapshot.t()

  @type snapshots :: list(Snapshot.t())

  @type time_start :: String.t()

  @type time_end :: String.t()

  @callback get_by_key(id()) :: snapshot()

  @callback get_by_key_and_revision(id(), revision()) :: snapshot()

  @callback get_all_snapshots_by_key(id()) :: snapshots()

  @callback get_snapshots_by_interval(id(), time_start(), time_end()) :: snapshots()

  @callback save(snapshot()) :: {:error, any} | {:ok, snapshot()}

  @callback default_port :: <<_::32>>

  defmacro __using__(_opts) do
    quote do
      alias Statestores.Adapters.SnapshotBehaviour
      import Statestores.Util, only: [init_config: 1, generate_key: 1]

      @behaviour Statestores.Adapters.SnapshotBehaviour

      def init(_type, config), do: init_config(config)
    end
  end
end
