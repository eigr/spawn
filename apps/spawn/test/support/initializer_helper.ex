defmodule Spawn.InitializerHelper do
  def setup do
    Spawn.Cluster.Node.Registry.start_link(%{})
  end
end
