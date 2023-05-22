defmodule Statestores.Schemas.Event do
  @moduledoc """
  App schema
  """
  use Ecto.Schema

  import Ecto.Changeset

  @type t() :: %__MODULE__{}

  @primary_key false
  schema "events" do
    field(:id, :integer, primary_key: true)

    field(:actor, :string)

    field(:system, :string)

    field(:revision, :integer)

    field(:tags, :map)

    field(:data_type, :string)

    field(:data, Statestores.Types.Binary)

    timestamps(type: :utc_datetime_usec)
  end

  @spec changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t() | {:error, Ecto.Changeset.t()}
  def changeset(event, attrs \\ %{}) do
    event
    |> cast(attrs, [:id, :actor, :system, :revision, :tags, :data_type, :data])
    |> validate_required([:id, :actor, :system, :revision, :tags, :data_type])
    |> case do
      %{valid?: false, changes: changes} = changeset when changes == %{} ->
        # If the changeset is invalid and has no changes, it is
        # because all required fields are missing, so we ignore it.
        %{changeset | action: :ignore}

      changeset ->
        changeset
    end
  end

  @spec from_record_tuple(term()) :: t()
  def from_record_tuple(tuple) do
    # Do not change the order here
    {_, actor, id, system, revision, tags, data_type, data, updated_at, inserted_at} = tuple

    %__MODULE__{
      actor: actor,
      id: id,
      system: system,
      revision: revision,
      tags: tags,
      data_type: data_type,
      data: data,
      updated_at: updated_at,
      inserted_at: inserted_at
    }
  end

  @spec to_record_list(t()) :: list(any())
  def to_record_list(%__MODULE__{} = event) do
    # Do not change the order here
    [
      event.actor,
      event.id,
      event.system,
      event.revision,
      event.tags,
      event.data_type,
      event.data,
      event.updated_at,
      event.inserted_at
    ]
  end
end
