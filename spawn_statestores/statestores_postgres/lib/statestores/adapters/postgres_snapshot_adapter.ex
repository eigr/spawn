defmodule Statestores.Adapters.PostgresSnapshotAdapter do
  @moduledoc """
  Implements the behavior defined in `Statestores.Adapters.SnapshotBehaviour` for Postgres databases.
  """
  use Statestores.Adapters.SnapshotBehaviour

  import Bitwise

  alias Statestores.Schemas.Snapshot
  alias Statestores.PostgresRepo

  def get_by_key(actor), do: PostgresRepo.get_by(Snapshot, actor: actor)

  def get_by_key_and_revision(_actor, _revision) do
  end

  def get_all_snapshots_by_key(_actor) do
  end

  def get_snapshots_by_interval(_actor, _time_start, _time_end) do
  end

  def save(%Snapshot{} = actual_snapshot) do
    %Snapshot{}
    |> Snapshot.changeset(%{
      id: random_64bit(),
      actor: actual_snapshot.actor,
      system: actual_snapshot.system,
      status: actual_snapshot.status,
      node: actual_snapshot.node,
      revision: actual_snapshot.revision || 0,
      tags: actual_snapshot.tags,
      data_type: actual_snapshot.data_type,
      data: actual_snapshot.data
    })
    |> PostgresRepo.insert_or_update(
      on_conflict: [
        set: [
          system: actual_snapshot.system,
          status: actual_snapshot.status,
          node: actual_snapshot.node,
          revision: (actual_snapshot.revision || 0) + 1,
          tags: actual_snapshot.tags,
          data_type: actual_snapshot.data_type,
          data: actual_snapshot.data,
          updated_at: DateTime.utc_now()
        ]
      ],
      conflict_target: [:actor]
    )
  end

  def default_port, do: "5432"

  defp random_64bit do
    # Generate a random unsigned 63-bit integer
    rand_unsigned = trunc(:rand.uniform() * (1 <<< 63))

    # Randomly choose whether to make it negative or positive
    if :rand.uniform() < 0.5 do
      rand_unsigned
    else
      -rand_unsigned
    end
  end
end
