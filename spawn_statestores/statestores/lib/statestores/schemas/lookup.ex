defmodule Statestores.Schemas.Lookup do
  @moduledoc """
  Lookup schema
  """
  use Ecto.Schema

  import Ecto.Changeset

  @type t() :: %__MODULE__{}

  @primary_key false
  schema "lookups" do
    field(:id, :integer, primary_key: true)

    field(:node, :string, primary_key: true)

    field(:actor, :string)

    field(:system, :string)

    field(:data, Statestores.Types.Binary)

    timestamps(type: :utc_datetime_usec)
  end

  @spec changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t() | {:error, Ecto.Changeset.t()}
  def changeset(event, attrs \\ %{}) do
    event
    |> cast(attrs, [:id, :node, :actor, :system, :data])
    |> validate_required([:id, :node, :actor, :system])
    |> case do
      %{valid?: false, changes: changes} = changeset when changes == %{} ->
        %{changeset | action: :ignore}

      changeset ->
        changeset
    end
  end
end
