defmodule ActivatorKafka.Application do
  @moduledoc false

  use Application

  Actors.Config.PersistentTermConfig as: Config
  import Activator, only: [get_http_port: 1]

  @impl true
  def start(_type, _args) do
    Config.load()

    children = [
      Activator.Supervisor.child_spec([]),
      {Bandit, plug: ActivatorKafka.Router, scheme: :http, port: get_http_port()}
    ]

    opts = [strategy: :one_for_one, name: ActivatorKafka.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
