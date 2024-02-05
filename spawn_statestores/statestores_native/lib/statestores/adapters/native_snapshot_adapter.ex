defmodule Statestores.Adapters.NativeSnapshotAdapter do
  @moduledoc """
  Implements the behavior defined in `Statestores.Adapters.Behaviour` for Native databases using Mnesia.
  """
  use Statestores.Adapters.SnapshotBehaviour
  use GenServer

  require Logger

  alias Statestores.Adapters.Native.SnapshotStore
  alias Statestores.Schemas.Snapshot

  @impl true
  def get_by_key(id) do
    :mnesia.dirty_index_read(SnapshotStore, id, :id)
    |> case do
      [] ->
        nil

      [data] ->
        Snapshot.from_record_tuple(data)

      error ->
        Logger.error("Error getting snapshot by key: #{inspect(error)} #{inspect(id)}")
        nil
    end
  end

  @impl true
  def get_by_key_and_revision(_id, _revision), do: raise("Not implemented")

  @impl true
  def get_all_snapshots_by_key(_id), do: raise("Not implemented")

  @impl true
  def get_snapshots_by_interval(_id, _time_start, _time_end), do: raise("Not implemented")

  @impl true
  def save(%Snapshot{} = snapshot) do
    snapshot_with_timestamps = %{
      snapshot
      | updated_at: DateTime.utc_now(),
        inserted_at: DateTime.utc_now()
    }

    :mnesia.transaction(fn ->
      :mnesia.write(
        List.to_tuple([SnapshotStore] ++ Snapshot.to_record_list(snapshot_with_timestamps))
      )
    end)
    |> case do
      {:atomic, :ok} ->
        {:ok, snapshot}

      error ->
        {:error, error}
    end
  end

  @impl true
  def default_port, do: <<00_000_000::32>>

  def child_spec(_),
    do: %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []}
    }

  def start_link, do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @impl GenServer
  def init(_), do: {:ok, nil}
end
