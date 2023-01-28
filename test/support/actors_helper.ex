defmodule Actors.ActorsHelper do
  @moduledoc false

  def registered_actors do
    Spawn.Cluster.StateHandoff |> Process.whereis() |> :sys.get_state() |> DeltaCrdt.to_map()
  end
end
