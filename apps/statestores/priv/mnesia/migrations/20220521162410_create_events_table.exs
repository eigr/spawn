defmodule Statestores.Adapters.Mnesia.Migrations.CreateEventsTable do
  use Ecto.Migration

  def up do

    IO.inspect :mnesia.create_table(:events, [
      disc_copies: [node()],
      record_name: Statestores.Schemas.Event,
      attributes: [:actor, :system, :revision, :tags, :data_type, :data, :updated_at, :inserted_at],
      type: :set
    ])
  end

end
