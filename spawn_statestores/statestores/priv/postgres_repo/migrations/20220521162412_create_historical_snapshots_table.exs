defmodule Statestores.PostgresRepo.Migrations.CreateHistoricalSnapshotsTable do
  use Ecto.Migration

  def up do
    create_if_not_exists table(:historical_snapshots, primary_key: false) do
      add(:historical_id, :bigserial, primary_key: true)
      add(:actor_id, :bigint)
      add(:actor, :string)
      add(:system, :string)
      add(:status, :string)
      add(:node, :string)
      add(:revision, :integer)
      add(:tags, :map)
      add(:data_type, :string)
      add(:data, :binary)
      add(:valid_from, :utc_datetime_usec)
      add(:valid_to, :utc_datetime_usec)
      timestamps(type: :utc_datetime_usec)
    end

    create_if_not_exists(index(:historical_snapshots, [:status]))
  end

  def down do
    drop(table(:historical_snapshots))
  end
end
