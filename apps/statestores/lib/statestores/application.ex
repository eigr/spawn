defmodule Statestores.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    type = String.to_existing_atom(System.get_env("PROXY_DATABASE_TYPE"))
    Statestores.Migrator.migrate()

    children = get_supervisor_tree(type)

    opts = [strategy: :one_for_one, name: Statestores.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp get_supervisor_tree(:mysql) do
    [Statestores.Vault, Statestores.Adapters.MySQL]
  end

  defp get_supervisor_tree(:postgres) do
    [Statestores.Vault, Statestores.Adapters.Postgres]
  end
end
