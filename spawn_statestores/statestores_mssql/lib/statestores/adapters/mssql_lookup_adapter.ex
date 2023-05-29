defmodule Statestores.Adapters.MSSQLLookupAdapter do
  @moduledoc """
  Implements the behavior defined in `Statestores.Adapters.LookupBehaviour` for MySql databases.
  """
  use Statestores.Adapters.LookupBehaviour

  use Ecto.Repo,
    otp_app: :spawn_statestores,
    adapter: Ecto.Adapters.Tds

  alias Statestores.Schemas.{Lookup, ValueObjectSchema}
end
