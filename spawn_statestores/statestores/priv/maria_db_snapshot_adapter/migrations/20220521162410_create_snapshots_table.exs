defmodule Statestores.Adapters.MariaDBSnapshotAdapter.Migrations.CreateSnapshotsTable do
  use Ecto.Migration

  def up do
    execute """
    CREATE TABLE IF NOT EXISTS snapshots (
      id BIGINT PRIMARY KEY,
      actor TEXT,
      system TEXT,
      status TEXT,
      node TEXT,
      revision BIGINT DEFAULT 0,
      tags JSON,
      data_type TEXT NOT NULL,
      data LONGBLOB,
      inserted_at TIMESTAMP,
      updated_at TIMESTAMP
    ) WITH SYSTEM VERSIONING;
    """

    create(index(:snapshots, [:status]))
  end

  def down do
    drop(table(:snapshots))
  end
end
