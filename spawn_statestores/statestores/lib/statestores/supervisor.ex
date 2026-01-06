defmodule Statestores.Supervisor do
  @moduledoc false
  use Supervisor

  @shutdown_timeout_ms 330_000

  import Statestores.Util,
    only: [
      load_repo: 0,
      supervisor_process_logger: 1
    ]

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__, shutdown: @shutdown_timeout_ms)
  end

  def child_spec() do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [[]]}
    }
  end

  @impl true
  def init(_args) do
    repo = load_repo()

    case System.get_env("MIX_ENV") do
      env when env in ["dev", "test"] ->
        Statestores.Migrator.migrate(repo)

      _ ->
        # TODO: migrate via job in production (future release)
        Statestores.Migrator.migrate(repo)
    end

    children =
      [
        supervisor_process_logger(__MODULE__),
        Statestores.Vault,
        repo
      ]
      |> maybe_add_native_children(repo)

    Supervisor.init(children, strategy: :one_for_one)
  end

  def maybe_add_native_children(children, Statestores.Adapters.NativeSnapshotAdapter) do
    children ++ Kernel.apply(Statestores.Adapters.Native.Children, :get_children, [])
  end

  def maybe_add_native_children(children, _), do: children
end
