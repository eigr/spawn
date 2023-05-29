defmodule Statestores.Adapters.SQLite3LookupAdapter do
  @moduledoc """
  Implements the behavior defined in `Statestores.Adapters.LookupBehaviour` for MySql databases.
  """
  use Statestores.Adapters.LookupBehaviour

  use Ecto.Repo,
    otp_app: :spawn_statestores,
    adapter: Ecto.Adapters.SQLite3

  alias Statestores.Schemas.{Lookup, ValueObjectSchema}
end
