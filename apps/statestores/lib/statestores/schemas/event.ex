defmodule Statestores.Schemas.Event do
  @moduledoc """
  App schema
  """
  use Ecto.Schema

  import Ecto.Changeset

  @type t() :: %__MODULE__{}

  @primary_key {:key, :string, []}
  schema "events" do
    field(:revision, :integer)

    field(:tags, :map)

    field(:data, :binary)

    timestamps()
  end

  @spec changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t() | {:error, Ecto.Changeset.t()}
  def changeset(event, attrs \\ %{}) do
    event
    |> cast(attrs, [:revision, :tags, :data])
    |> validate_required([:revision, :data])
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
