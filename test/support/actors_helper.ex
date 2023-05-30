defmodule Actors.ActorsHelper do
  @moduledoc false

  def registered_actors do
    Spawn.Cluster.StateHandoffManager.get_crdt_pid() |> DeltaCrdt.to_map()
  end
end
