defmodule Statestores.Adapters.MySQLLookupAdapter do
  @moduledoc """
  Implements the behavior defined in `Statestores.Adapters.LookupBehaviour` for MySql databases.
  """
  use Statestores.Adapters.LookupBehaviour

  use Ecto.Repo,
    otp_app: :spawn_statestores,
    adapter: Ecto.Adapters.MyXQL

  import Ecto.Query, only: [from: 2]

  alias Statestores.Schemas.{Lookup, ValueObjectSchema}

  def get_by_key(id), do: {:ok, all(from(l in Lookup, where: l.id == ^id))}

  def get(%{id: id, node: host} = _id) do
    res = all(from(l in Lookup, where: l.id == ^id and l.node == ^node))
    {:ok, res}
  end

  def get_all_by_node(%{node: host} = _id) do
    res = all(from(l in Lookup, where: l.node == ^node))
    {:ok, res}
  end
end
