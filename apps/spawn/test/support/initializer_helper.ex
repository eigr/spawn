defmodule Spawn.InitializerHelper do
  def setup do
    config = Actors.Config.Vapor.load(__MODULE__)
    Sidecar.Supervisor.start_link(config)
  end
end
