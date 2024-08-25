defmodule Statestores.Schemas.HistoricalSnapshot do
  @moduledoc """
  Schema for the historical snapshot records.
  """
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false
  schema "historical_snapshots" do
    field(:actor_id, :integer)
    field(:actor, :string)
    field(:system, :string)
    field(:status, :string)
    field(:node, :string)
    field(:revision, :integer)
    field(:tags, :map)
    field(:data_type, :string)
    field(:data, Statestores.Types.Binary)
    field(:valid_from, :utc_datetime_usec)
    field(:valid_to, :utc_datetime_usec)
    timestamps(type: :utc_datetime_usec)
  end

  @spec changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t() | {:error, Ecto.Changeset.t()}
  def changeset(event, attrs \\ %{}) do
    event
    |> cast(attrs, [
      :actor_id,
      :actor,
      :system,
      :status,
      :node,
      :revision,
      :tags,
      :data_type,
      :data,
      :valid_from,
      :valid_to
    ])
    |> validate_required([
      :actor_id,
      :actor,
      :system,
      :status,
      :node,
      :revision,
      :tags,
      :data_type
    ])
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
