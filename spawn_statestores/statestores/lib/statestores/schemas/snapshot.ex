defmodule Statestores.Schemas.Snapshot do
  @moduledoc """
  Snapshot schema
  """
  use Ecto.Schema

  import Ecto.Changeset

  @type t() :: %__MODULE__{}

  @primary_key false
  schema "snapshots" do
    field(:id, :integer, primary_key: true)
    field(:actor, :string)
    field(:system, :string)
    field(:status, :string)
    field(:node, :string)
    field(:revision, :integer)
    field(:tags, :map)
    field(:data_type, :string)
    field(:data, Statestores.Types.Binary)
    timestamps(type: :utc_datetime_usec)
  end

  @spec changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t() | {:error, Ecto.Changeset.t()}
  def changeset(event, attrs \\ %{}) do
    event
    |> cast(attrs, [:id, :actor, :system, :status, :node, :revision, :tags, :data_type, :data])
    |> validate_required([:id, :actor, :system, :status, :node, :revision, :tags, :data_type])
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
