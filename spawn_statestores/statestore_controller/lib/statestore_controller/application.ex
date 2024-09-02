defmodule StatestoreController.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {StatestoreController.Supervisor, []}
    ]

    opts = [strategy: :one_for_one, name: StatestoreController.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
