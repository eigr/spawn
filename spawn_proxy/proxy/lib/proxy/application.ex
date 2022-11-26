defmodule Proxy.Application do
  @moduledoc false
  use Application

  alias Actors.Config.Vapor, as: Config

  @impl true
  def start(_type, _args) do
    config = Config.load(__MODULE__)

    children = [
      {Proxy.Supervisor, config}
    ]

    opts = [strategy: :one_for_one, name: Proxy.RootSupervisor]
    Supervisor.start_link(children, opts)
  end
end
