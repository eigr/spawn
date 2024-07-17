defmodule Spawn.Supervisor do
  @moduledoc false
  use Supervisor
  require Logger

  import Spawn.Utils.Common, only: [supervisor_process_logger: 1]

  alias Actors.Config.PersistentTermConfig, as: Config

  alias Spawn.Cluster.Node.Distributor

  @shutdown_timeout_ms 330_000

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      shutdown: @shutdown_timeout_ms
    }
  end

  @impl true
  def init(opts) do
    children =
      ([
         supervisor_process_logger(__MODULE__),
         {Spawn.Cache.LookupCache, []},
         {Spawn.Cluster.ClusterSupervisor, []}
       ] ++ Distributor.child_specs())
      |> maybe_start_internal_nats(opts)

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp maybe_start_internal_nats(children, opts) do
    case Config.get(:use_internal_nats) do
      false ->
        children

      _ ->
        Logger.debug("Starting Spawn using Nats control protocol")

        (children ++
           [
             Spawn.Cluster.Node.ConnectionSupervisor.child_spec(opts),
             Spawn.Cluster.Node.ServerSupervisor.child_spec(opts)
           ])
        |> List.flatten()
    end
  end
end
