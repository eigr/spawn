defmodule Statestores.Adapters.MySQLLookupAdapter do
  @moduledoc """
  Implements the behavior defined in `Statestores.Adapters.LookupBehaviour` for MySql databases.
  """
  use Statestores.Adapters.LookupBehaviour

  use Ecto.Repo,
    otp_app: :spawn_statestores,
    adapter: Ecto.Adapters.MyXQL

  alias Statestores.Schemas.{Lookup, ValueObjectSchema}

  @impl true
  def clean(node) do
    node = Atom.to_string(node)
    res = delete_all(from(l in Lookup, where: l.node == ^node))
    {:ok, res}
  end

  @impl true
  def get_all_by_node(node) do
    node = Atom.to_string(node)
    res = all(from(l in Lookup, where: l.node == ^node))
    {:ok, res}
  end

  @impl true
  def get_by_id(id) do
    key = generate_key(id)
    {:ok, all(from(l in Lookup, where: l.id == ^key, select: l.data))}
  end

  @impl true
  def get_by_id_node(id, node) do
    node = Atom.to_string(node)
    res = all(from(l in Lookup, where: l.id == ^id and l.node == ^node, select: l.data))
    {:ok, res}
  end

  @impl true
  def set(%{name: actor, system: system} = id, node, data) do
    key = generate_key(id)
    node = Atom.to_string(node)

    event = %Lookup{
      id: key,
      node: node,
      actor: actor,
      system: system,
      data: data
    }

    %Lookup{}
    |> Lookup.changeset(ValueObjectSchema.to_map(event))
    |> insert_or_update(
      on_conflict: [
        set: [
          actor: actor,
          system: system,
          data: data,
          updated_at: DateTime.utc_now()
        ]
      ]
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
end
