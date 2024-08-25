defmodule Statestores.Adapters.PostgresSnapshotAdapter.Migrations.CreateSnapshotsTables do
  use Ecto.Migration

  def up do
    create table(:snapshots, primary_key: false) do
      add(:id, :bigint, primary_key: true)
      add(:actor, :string)
      add(:system, :string)
      add(:status, :string)
      add(:node, :string)
      add(:revision, :integer, default: 0)
      add(:tags, :map)
      add(:data_type, :string)
      add(:data, :binary)
      timestamps(type: :utc_datetime_usec)
    end

    create(index(:snapshots, [:status]))

    create table(:historical_snapshots, primary_key: false) do
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

    create(index(:historical_snapshots, [:status]))
  end

  def down do
    drop(table(:snapshots))
    drop(table(:historical_snapshots))
  end
end
