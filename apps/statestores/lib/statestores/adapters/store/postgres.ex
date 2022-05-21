defmodule Statestores.Adapters.Store.Postgres do
  use Ecto.Repo,
    otp_app: :statestores,
    adapter: Ecto.Adapters.Postgres
end
