defmodule Statestores.Adapters.MSSQL do
  use Statestores.Adapters.Behaviour

  use Ecto.Repo,
    otp_app: :statestores,
    adapter: Ecto.Adapters.Tds

  alias Statestores.Schemas.{Event, ValueObjectSchema}

  def get_by_key(actor), do: get_by(Event, actor: actor)

  def save(%Event{actor: actor} = event) do
    %Event{}
    |> Event.changeset(ValueObjectSchema.to_map(event))
    |> insert!()
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
      get_by(Event, actor: actor)
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
end
