defmodule Statestores.PostgresRepo do
  use Ecto.Repo,
    otp_app: :spawn_statestores,
    adapter: Ecto.Adapters.Postgres

  import Statestores.Util, only: [init_config: 1]

  def init(_type, config), do: init_config(config)
end
