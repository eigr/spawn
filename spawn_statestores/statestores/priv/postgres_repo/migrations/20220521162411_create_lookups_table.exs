defmodule Statestores.PostgresRepo.Migrations.CreateLookupsTable do
  use Ecto.Migration

  def up do
    create_if_not_exists table(:lookups, primary_key: false) do
      add :id, :bigint, primary_key: true
      add :node, :string, primary_key: true
      add :actor, :string
      add :system, :string
      add :data, :binary
      timestamps([type: :utc_datetime_usec])
    end

    create_if_not_exists unique_index(:lookups, [:id, :node])
    create_if_not_exists index(:lookups, [:node])
  end

  def down do
    drop table(:lookups)
  end
end
