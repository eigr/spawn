defmodule Statestores.Adapters.MySQL do
  use Ecto.Repo,
    otp_app: :statestores,
    adapter: Ecto.Adapters.MyXQL

  @behaviour Statestores.Adapters.Behaviour

  alias Statestores.Schemas.{Event, ValueObjectSchema}

  @impl true
  def init(_type, config) do
    config =
      case System.get_env("MIX_ENV") do
        "test" -> Keyword.put(config, :pool, Ecto.Adapters.SQL.Sandbox)
        _ -> config
      end

    config =
      Keyword.put(config, :database, System.get_env("PROXY_DATABASE_NAME", "eigr-functions-db"))

    config = Keyword.put(config, :username, System.get_env("PROXY_DATABASE_USERNAME", "admin"))
    config = Keyword.put(config, :password, System.get_env("PROXY_DATABASE_SECRET", "admin"))
    config = Keyword.put(config, :hostname, System.get_env("PROXY_DATABASE_HOST", "localhost"))

    config =
      Keyword.put(config, :port, String.to_integer(System.get_env("PROXY_DATABASE_PORT", "3306")))

    {:ok, config}
  end

  @impl Statestores.Adapters.Behaviour
  def get_by_key(actor), do: get_by(Event, actor: actor)

  @impl Statestores.Adapters.Behaviour
  def save(
        %Event{actor: _actor, revision: revision, tags: tags, data_type: type, data: data} = event
      ) do
    map_event = ValueObjectSchema.to_map(event)

    %Event{}
    |> Event.changeset(map_event)
    |> insert!(on_conflict: [set: [revision: revision, tags: tags, data_type: type, data: data]])
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
