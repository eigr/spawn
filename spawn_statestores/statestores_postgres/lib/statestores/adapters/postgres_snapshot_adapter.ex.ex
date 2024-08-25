defmodule Statestores.Adapters.PostgresSnapshotAdapter do
  @moduledoc """
  Implements the behavior defined in `Statestores.Adapters.SnapshotBehaviour` for Postgres databases.
  """
  use Statestores.Adapters.SnapshotBehaviour

  use Ecto.Repo,
    otp_app: :spawn_statestores,
    adapter: Ecto.Adapters.Postgres

  alias Statestores.Schemas.{Snapshot, HistoricalSnapshot}

  def get_by_key(id), do: get_by(Snapshot, id: id)

  def get_by_key_and_revision(id, revision) do
    query = """
    SELECT *
      FROM historical_snapshots
     WHERE id = #{id}
       AND revision = #{revision}
     ORDER BY inserted_at DESC, updated_at DESC
    """

    %Postgrex.Result{rows: rows} =
      Ecto.Adapters.SQL.query!(Statestores.Adapters.PostgresSnapshotAdapter, query)

    List.first(rows)
    |> to_snapshot(:historical)
    |> case do
      nil -> get_by_key(id)
      response -> response
    end
  end

  def get_all_snapshots_by_key(id) do
    query = "SELECT * FROM historical_snapshots WHERE actor_id = #{id}"

    %Postgrex.Result{rows: rows} =
      Ecto.Adapters.SQL.query!(Statestores.Adapters.PostgresSnapshotAdapter, query)

    rows
    |> Enum.map(&to_snapshot(&1, :historical))
  end

  def get_snapshots_by_interval(id, time_start, time_end) do
    query = """
    SELECT *
      FROM historical_snapshots
     WHERE actor_id = #{id}
       AND valid_from <= '#{time_end}'
       AND valid_to >= '#{time_start}'
     ORDER BY inserted_at ASC, updated_at ASC
    """

    %Postgrex.Result{rows: rows} =
      Ecto.Adapters.SQL.query!(Statestores.Adapters.PostgresSnapshotAdapter, query)

    rows
    |> Enum.map(&to_snapshot(:historical, &1))
  end

  def save(%Snapshot{} = actual_snapshot) do
    __MODULE__.transaction(fn ->
      case get_by_key(actual_snapshot.id) do
        nil ->
          # Insert the new snapshot as there's no previous one
          insert_new_snapshot(actual_snapshot)

        previous_snapshot ->
          # Move the previous snapshot to historical_snapshots
          move_to_historical_snapshots(previous_snapshot)

          # Update the current snapshot with the new data
          update_snapshot(previous_snapshot, actual_snapshot)
      end
    end)
  end

  defp insert_new_snapshot(%Snapshot{} = snapshot) do
    snapshot
    |> Map.put(:revision, 1)
    |> __MODULE__.insert()
  end

  defp move_to_historical_snapshots(%Snapshot{} = previous_snapshot) do
    %HistoricalSnapshot{
      actor_id: previous_snapshot.id,
      actor: previous_snapshot.actor,
      system: previous_snapshot.system,
      status: previous_snapshot.status,
      node: previous_snapshot.node,
      revision: previous_snapshot.revision,
      tags: previous_snapshot.tags,
      data_type: previous_snapshot.data_type,
      data: previous_snapshot.data,
      valid_from: previous_snapshot.inserted_at,
      valid_to: previous_snapshot.updated_at
    }
    |> __MODULE__.insert()
  end

  defp update_snapshot(%Snapshot{} = previous_snapshot, %Snapshot{} = actual_snapshot) do
    changeset =
      actual_snapshot
      |> Map.put(:revision, previous_snapshot.revision + 1)
      |> build_snapshot_changeset(previous_snapshot)

    __MODULE__.update(changeset)
  end

  def default_port, do: "5432"

  defp build_snapshot_changeset(%Snapshot{} = snapshot, %Snapshot{} = previous_snapshot) do
    previous_snapshot
    |> Snapshot.changeset(%{
      id: snapshot.id,
      actor: snapshot.actor,
      system: snapshot.system,
      status: snapshot.status,
      node: snapshot.node,
      revision: snapshot.revision || 0,
      tags: snapshot.tags,
      data_type: snapshot.data_type,
      data: snapshot.data
    })
  end

  defp to_snapshot(row, :current) do
    data = Statestores.Vault.decrypt!(Enum.at(row, 8))

    %Snapshot{
      id: Enum.at(row, 0),
      actor: Enum.at(row, 1),
      system: Enum.at(row, 2),
      status: Enum.at(row, 3),
      node: Enum.at(row, 4),
      revision: Enum.at(row, 5),
      tags: Enum.at(row, 6),
      data_type: Enum.at(row, 7),
      data: data,
      inserted_at: Enum.at(row, 9),
      updated_at: Enum.at(row, 10)
    }
  end

  defp to_snapshot(row, :historical) do
    data = Statestores.Vault.decrypt!(Enum.at(row, 9))

    %Snapshot{
      id: Enum.at(row, 1),
      actor: Enum.at(row, 2),
      system: Enum.at(row, 3),
      status: Enum.at(row, 4),
      node: Enum.at(row, 5),
      revision: Enum.at(row, 6),
      tags: Enum.at(row, 7),
      data_type: Enum.at(row, 8),
      data: data,
      inserted_at: Enum.at(row, 12),
      updated_at: Enum.at(row, 13)
    }
  end
end
