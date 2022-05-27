defmodule Statestores.Schemas.Event do
  @moduledoc """
  App schema
  """
  use Ecto.Schema

  import Ecto.Changeset

  @type t() :: %__MODULE__{}

  @primary_key {:id, :id, autogenerate: true}
  schema "events" do
    field(:system, :string)

    field(:actor, :string)

    field(:revision, :integer)

    field(:tags, :map)

    field(:data_type, :string)

    field(:data, :binary)

    timestamps()
  end

  @spec changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t() | {:error, Ecto.Changeset.t()}
  def changeset(event, attrs \\ %{}) do
    event
    |> cast(attrs, [:actor, :revision, :tags, :data_type, :data])
    |> validate_required([:actor, :revision, :tags, :data_type, :data])
    |> unique_constraint(:actor)
    |> case do
      %{valid?: false, changes: changes} = changeset when changes == %{} ->
        # If the changeset is invalid and has no changes, it is
        # because all required fields are missing, so we ignore it.
        %{changeset | action: :ignore}

      changeset ->
        changeset
    end
  end
end
