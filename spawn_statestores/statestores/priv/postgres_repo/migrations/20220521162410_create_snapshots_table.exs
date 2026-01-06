defmodule Statestores.PostgresRepo.Migrations.CreateSnapshotsTable do
  use Ecto.Migration

  def up do
    create_if_not_exists table(:snapshots, primary_key: false) do
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

    create_if_not_exists(index(:snapshots, [:status]))
  end

  def down do
    drop(table(:snapshots))
  end
end
