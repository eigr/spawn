defmodule Statestores.Schemas.Lookup do
  @moduledoc """
  App schema
  """
  use Ecto.Schema

  import Ecto.Changeset

  @type t() :: %__MODULE__{}

  @primary_key false
  schema "lookups" do
    field(:id, :integer, primary_key: true)

    field(:node, :string)

    field(:actor, :string)

    field(:system, :string)

    field(:data, Statestores.Types.Binary)

    timestamps(type: :utc_datetime_usec)
  end

  @spec changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t() | {:error, Ecto.Changeset.t()}
  def changeset(event, attrs \\ %{}) do
    event
    |> cast(attrs, [:id, :actor, :system, :node, :data])
    |> validate_required([:id, :actor, :system, :node])
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
