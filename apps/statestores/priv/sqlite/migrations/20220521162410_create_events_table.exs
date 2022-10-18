defmodule Statestores.Adapters.SQLite3.Migrations.CreateEventsTable do
  use Ecto.Migration

  def up do
    # create table(:events, primary_key: false) do
    #   add :actor, :string, primary_key: true
    #   add :system, :string
    #   add :revision, :integer
    #   add :tags, :map
    #   add :data_type, :string
    #   add :data, :binary
    #   timestamps([type: :utc_datetime_usec])
    # end

    execute """
    CREATE TABLE IF NOT EXISTS events (
      actor TEXT PRIMARY KEY,
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
