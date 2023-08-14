defmodule Statestores.Adapters.MariaDBSnapshotAdapter do
  @moduledoc """
  Implements the behavior defined in `Statestores.Adapters.SnapshotBehaviour` for MariaDB databases.
  """
  use Statestores.Adapters.SnapshotBehaviour

  use Ecto.Repo,
    otp_app: :spawn_statestores,
    adapter: Ecto.Adapters.MyXQL

  alias Statestores.Schemas.{Snapshot, ValueObjectSchema}

  def get_by_key(id), do: get_by(Snapshot, id: id)

  def get_by_key_and_revision(id, revision) do
    query =
      "SELECT * FROM snapshots FOR SYSTEM_TIME ALL WHERE id = #{id} AND revision = #{revision} ORDER BY inserted_at, updated_at DESC"

    %MyXQL.Result{rows: rows} =
      Ecto.Adapters.SQL.query!(Statestores.Adapters.MariaDBSnapshotAdapter, query)

    List.first(rows)
    |> to_snapshot()
    |> case do
      nil ->
        get_by_key(id)

      response ->
        response
    end
  end

  def get_all_snapshots_by_key(id) do
    query = "SELECT * FROM snapshots FOR SYSTEM_TIME ALL WHERE id = #{id}"

    %MyXQL.Result{rows: rows} =
      Ecto.Adapters.SQL.query!(Statestores.Adapters.MariaDBSnapshotAdapter, query)

    rows
    |> Enum.map(&to_snapshot/1)
  end

  def get_snapshots_by_interval(id, time_start, time_end) do
    query = """
    SELECT *
      FROM snapshots
       FOR SYSTEM_TIME BETWEEN '#{time_start}' AND '#{time_end}'
     WHERE id = #{id}
     ORDER BY inserted_at, updated_at ASC
    """

    %MyXQL.Result{rows: rows} =
      Ecto.Adapters.SQL.query!(Statestores.Adapters.MariaDBSnapshotAdapter, query)

    rows
    |> Enum.map(&to_snapshot/1)
  end

  def save(
        %Snapshot{
          system: system,
          actor: actor,
          status: status,
          node: node,
          revision: revision,
          tags: tags,
          data_type: type,
          data: data
        } = event
      ) do
    %Snapshot{}
    |> Snapshot.changeset(ValueObjectSchema.to_map(event))
    |> insert_or_update(
      on_conflict: [
        set: [
          system: system,
          actor: actor,
          status: status,
          node: node,
          revision: revision,
          tags: tags,
          data_type: type,
          data: data,
          updated_at: DateTime.utc_now()
        ]
      ]
    )
    |> case do
      {:ok, event} ->
        {:ok, event}

      {:error, changeset} ->
        {:error, changeset}

      other ->
        {:error, other}
    end
  end

  def default_port, do: "3306"

  defp to_map(json) when is_nil(json) or json == "", do: %{}

  defp to_map(tags) do
    case Jason.decode(tags) do
      {:ok, json} -> json
      _ -> %{}
    end
  end

  defp to_snapshot(nil), do: nil

  defp to_snapshot(row) do
    tags = to_map(Enum.at(row, 6))

    %Statestores.Schemas.Snapshot{
      id: Enum.at(row, 0),
      actor: Enum.at(row, 1),
      system: Enum.at(row, 2),
      status: Enum.at(row, 3),
      node: Enum.at(row, 4),
      revision: Enum.at(row, 5),
      tags: tags,
      data_type: Enum.at(row, 7),
      data: Enum.at(row, 8),
      inserted_at: Enum.at(row, 9),
      updated_at: Enum.at(row, 10)
    }
  end
end
