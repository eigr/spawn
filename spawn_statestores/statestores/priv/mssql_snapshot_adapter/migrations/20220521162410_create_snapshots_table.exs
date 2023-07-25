defmodule Statestores.Adapters.MSSQLSnapshotAdapter.Migrations.CreateSnapshotsTable do
  use Ecto.Migration

  def up do
    create table(:snapshots, primary_key: false) do
      add :id, :bigint, primary_key: true
      add :actor, :string
      add :system, :string
      add :status, :string
      add :node, :string
      add :revision, :integer
      add :tags, :map
      add :data_type, :string
      add :data, :binary
      timestamps([type: :utc_datetime_usec])
    end

    create index(:snapshots, [:status])
  end

  def down do
    drop table(:snapshots)
  end
end
