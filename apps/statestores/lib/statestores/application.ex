defmodule Statestores.Application do
  @moduledoc false

  use Application
  import Statestores.Util, only: [load_repo: 0]

  @impl true
  def start(_type, _args) do
    Statestores.Migrator.migrate()

    children = [
      Statestores.Vault,
      load_repo()
    ]

    opts = [strategy: :one_for_one, name: Statestores.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
