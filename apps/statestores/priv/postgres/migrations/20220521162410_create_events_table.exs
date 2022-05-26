defmodule Statestores.Adapters.Postgres.Migrations.CreateEventsTable do
  use Ecto.Migration

  def change do
    create table(:events, primary_key: false) do
      add :key, :string, primary_key: true
      add :revision, :integer
      add :tags, :map
      add :data, :binary
      timestamps()
    end
  end
end
