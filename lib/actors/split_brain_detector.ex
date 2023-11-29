defmodule Actors.SplitBrainDetector do
  @moduledoc """

  """
  @type status :: String.t()
  @type node_id :: String.t()
  @type actor_id :: Eigr.Functions.Protocol.Actors.ActorId.t()

  @callback check_network_partition(actor_id(), status(), node_id()) ::
              {:ok, :continue} | {:error, :network_partition_detected}

  @callback check_network_partition!(actor_id(), status(), node_id()) ::
              {:ok, :continue} | Exception.t()
end
