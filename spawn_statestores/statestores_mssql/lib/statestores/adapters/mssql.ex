defmodule Statestores.Adapters.MSSQL do
  @moduledoc """
  Implements the behavior defined in `Statestores.Adapters.Behaviour` for MSSQL databases.
  """
  use Statestores.Adapters.Behaviour

  use Ecto.Repo,
    otp_app: :spawn_statestores,
    adapter: Ecto.Adapters.Tds

  alias Statestores.Schemas.{Event, ValueObjectSchema}

  def get_by_key(id), do: get_by(Event, id: id)

  def save(%Event{id: id} = event) do
    %Event{}
    |> Event.changeset(ValueObjectSchema.to_map(event))
    |> insert()
    |> case do
      {:ok, event} ->
        {:ok, event}

      {:error, changeset} ->
        {:error, changeset}

      other ->
        {:error, other}
    end
  rescue
    _e ->
      get_by(Event, id: id)
      |> Event.changeset(ValueObjectSchema.to_map(event))
      |> update!()
      |> case do
        {:ok, event} ->
          {:ok, event}

        {:error, changeset} ->
          {:error, changeset}

        other ->
          {:error, other}
      end
  end

  def default_port, do: "1433"
end
