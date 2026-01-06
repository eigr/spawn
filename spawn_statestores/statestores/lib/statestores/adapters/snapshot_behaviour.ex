defmodule Statestores.Adapters.SnapshotBehaviour do
  @moduledoc """
  Defines the default behavior for each Statestore Provider.
  """
  alias Statestores.Schemas.Snapshot

  @type actor :: String.t()

  @type revision :: integer()

  @type snapshot :: Snapshot.t()

  @type snapshots :: list(Snapshot.t())

  @type time_start :: String.t()

  @type time_end :: String.t()

  @callback get_by_key(actor()) :: snapshot()

  @callback get_by_key_and_revision(actor(), revision()) :: snapshot()

  @callback get_all_snapshots_by_key(actor()) :: snapshots()

  @callback get_snapshots_by_interval(actor(), time_start(), time_end()) :: snapshots()

  @callback save(snapshot()) :: {:error, any} | {:ok, snapshot()}

  @callback default_port :: <<_::32>>

  defmacro __using__(_opts) do
    quote do
      alias Statestores.Adapters.SnapshotBehaviour
      import Statestores.Util, only: [generate_key: 1]

      @behaviour Statestores.Adapters.SnapshotBehaviour
    end
  end
end
