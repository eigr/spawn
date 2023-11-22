defmodule ActivatorSQS.Application do
  @moduledoc false

  use Application

  Actors.Config.PersistentTermConfig as: Config
  import Activator, only: [get_http_port: 1]

  @impl true
  def start(_type, _args) do
    Config.load()

    children = [
      Activator.Supervisor.child_spec([]),
      {Bandit, plug: ActivatorSQS.Router, scheme: :http, port: get_http_port()}
    ]

    opts = [strategy: :one_for_one, name: ActivatorSQS.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
