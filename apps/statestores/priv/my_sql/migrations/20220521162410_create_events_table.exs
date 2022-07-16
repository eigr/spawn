defmodule Statestores.Adapters.MySQL.Migrations.CreateEventsTable do
  use Ecto.Migration

  def change do
    create table(:events) do
      add :actor, :string
      add :revision, :integer
      add :tags, :map
      add :data_type, :string
      add :data, :binary
      timestamps()
    end

    create unique_index(:events, :actor)
  end
end
