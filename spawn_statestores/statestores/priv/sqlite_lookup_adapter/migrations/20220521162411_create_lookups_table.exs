defmodule Statestores.Adapters.SQLite3LookupAdapter.Migrations.CreateLookupsTable do
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
  end

  def down do
    drop table(:lookups)
  end
end
