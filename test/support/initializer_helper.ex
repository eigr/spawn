defmodule Spawn.InitializerHelper do
  @moduledoc false

  def setup do
    config = Actors.Config.Vapor.load(__MODULE__)
    result = Sidecar.Supervisor.start_link(config)

    Spawn.Cluster.StateHandoff.Manager.clean(Node.self())

    result
  end

  def spawn_peer(name) do
    node = Spawn.NodeHelper.spawn_peer(name, applications: [:spawn])

    case Spawn.NodeHelper.rpc(node, Spawn.InitializerHelper, :setup, []) do
      {:error, error} ->
        IO.puts(
          "** Failed to start sidecar in the peer node, check if applications are correctly started"
        )

        throw(error)

      {:ok, pid} ->
        IO.puts("** Sidecar successfully started in peer node in pid=#{inspect(pid)}")
    end
  end
end
