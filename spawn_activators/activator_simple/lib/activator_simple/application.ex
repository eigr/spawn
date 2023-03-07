defmodule ActivatorSimple.Application do
  @moduledoc false

  use Application
  require Logger

  alias Actors.Config.Vapor, as: Config
  alias ActivatorSimple.Supervisor, as: SimpleSupervisor

  @impl true
  def start(_type, _args) do
    config = Config.load(__MODULE__)

    children = [
      {SimpleSupervisor, config}
    ]

    opts = [strategy: :one_for_one, name: ActivatorSimple.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
