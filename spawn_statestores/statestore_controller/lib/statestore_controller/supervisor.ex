defmodule StatestoreController.Supervisor do
  @moduledoc false

  import Statestores.Util, only: [load_repo: 0]

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def child_spec(args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [args]}
    }
  end

  @impl true
  def init(args) do
    repo = load_repo()

    Statestores.Migrator.migrate(repo)

    children =
      [
        Statestores.Vault,
        repo,
        {StatestoreController.CDC.CdcSupervisor, [args]}
      ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
