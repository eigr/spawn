defmodule Statestores.Adapters.SQLite3SnapshotAdapter.Migrations.CreateEventsTable do
  use Ecto.Migration

  def up do
    execute """
    CREATE TABLE IF NOT EXISTS lookups (
      id INTEGER,
      node TEXT,
      actor TEXT,
      system TEXT,
      data BLOB,
      inserted_at TEXT_DATETIME,
      updated_at TEXT_DATETIME,
      PRIMARY KEY (id, node)
    )
    """

    execute """
    CREATE TABLE IF NOT EXISTS snapshots (
      id INTEGER PRIMARY KEY,
      actor TEXT,
      system TEXT,
      revision INTEGER DEFAULT 0,
      tags JSON,
      data_type TEXT NOT NULL,
      data BLOB,
      inserted_at TEXT_DATETIME,
      updated_at TEXT_DATETIME
    )
    """
  end

  def down do
    drop table(:snapshots)
    drop table(:lookups)
  end
end
