defmodule Statestores.Schemas.Projection do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  schema "projection_placeholder" do
    field :projection_id, :string
    field :projection_name, :string
    field(:system, :string)
    field :metadata, :map
    field :data_type, :string
    field(:data, Statestores.Types.Binary)
    field :inserted_at, :naive_datetime
    field :updated_at, :naive_datetime
  end

  @doc false
  def changeset(projection, attrs) do
    projection
    |> cast(attrs, [:id, :projection_id, :projection_name, :system, :metadata, :data_type, :data])
    |> validate_required([
      :id,
      :projection_id,
      :projection_name,
      :system,
      :metadata,
      :data_type,
      :data
    ])
    |> case do
      %{valid?: false, changes: changes} = changeset when changes == %{} ->
        %{changeset | action: :ignore}

      changeset ->
        changeset
    end
  end
end
