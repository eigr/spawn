defmodule Statestores.PostgresRepo.Migrations.ChangePrimaryKeyToActorAndDropId do
  use Ecto.Migration
  @disable_ddl_transaction true
  
  def up do
    # Ensure actor can be a primary key (optional safety check)
    execute """
    DO $$
    BEGIN
      IF EXISTS (
        SELECT actor
        FROM snapshots
        WHERE actor IS NULL
        OR actor IN (SELECT actor FROM snapshots GROUP BY actor HAVING COUNT(*) > 1)
      ) THEN
        RAISE EXCEPTION 'Cannot set actor as primary key: column contains NULL or duplicate values';
      END IF;
    END
    $$;
    """

    create_if_not_exists index(:snapshots, [:actor], unique: true, concurrently: true)
  end
  
  def down do
    drop_if_exists index(:snapshots, [:actor], unique: true)
  end
end
