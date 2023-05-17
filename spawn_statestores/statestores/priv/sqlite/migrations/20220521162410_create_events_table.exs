defmodule Statestores.Adapters.SQLite3.Migrations.CreateEventsTable do
  use Ecto.Migration

  def up do
    execute """
    CREATE TABLE IF NOT EXISTS events (
      id TEXT PRIMARY KEY,
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
    drop table(:events)
  end
end
