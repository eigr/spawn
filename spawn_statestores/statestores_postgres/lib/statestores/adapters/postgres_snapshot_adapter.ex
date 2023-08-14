defmodule Statestores.Adapters.PostgresSnapshotAdapter do
  @moduledoc """
  Implements the behavior defined in `Statestores.Adapters.SnapshotBehaviour` for Postgres databases.
  """
  use Statestores.Adapters.SnapshotBehaviour

  use Ecto.Repo,
    otp_app: :spawn_statestores,
    adapter: Ecto.Adapters.Postgres

  alias Statestores.Schemas.{Snapshot, ValueObjectSchema}

  def get_by_key(id), do: get_by(Snapshot, id: id)

  def get_by_key_and_revision(_id, _revision), do: raise("Not implemented")

  def get_all_snapshots_by_key(_id), do: raise("Not implemented")

  def get_snapshots_by_interval(_id, _time_start, _time_end), do: raise("Not implemented")

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
      ],
      conflict_target: :id
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

  def default_port, do: "5432"
end
