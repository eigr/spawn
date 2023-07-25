defmodule Actors.SplitBrainDetector do
  @moduledoc """

  """
  @type status :: String.t()
  @type node_id :: String.t()

  @callback check_network_partition(status(), node_id()) ::
              {:ok, :continue} | {:error, :network_partition_detected}

  @callback check_network_partition!(status(), node_id()) :: {:ok, :continue} | Exception.t()
end
