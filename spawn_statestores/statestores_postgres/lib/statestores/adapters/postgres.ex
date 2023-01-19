defmodule Statestores.Adapters.Postgres do
  use Statestores.Adapters.Behaviour

  use Ecto.Repo,
    otp_app: :spawn_statestores,
    adapter: Ecto.Adapters.Postgres

  alias Statestores.Schemas.{Event, ValueObjectSchema}

  def get_by_key(actor), do: get_by(Event, actor: actor)

  def save(%Event{revision: revision, tags: tags, data_type: type, data: data} = event) do
    %Event{}
    |> Event.changeset(ValueObjectSchema.to_map(event))
    |> insert_or_update(
      on_conflict: [
        set: [
          revision: revision,
          tags: tags,
          data_type: type,
          data: data,
          updated_at: DateTime.utc_now()
        ]
      ],
      conflict_target: :actor
    )
    |> case do
      {:ok, event} ->
        {:ok, event}

      {:error, changeset} ->
        {:error, changeset}

      other ->
        {:error, other}
    end
  end

  def default_port, do: "5432"
end
