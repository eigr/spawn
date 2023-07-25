defmodule Actors.Node.DefaultSplitBrainDetector do
  @moduledoc false
  @behaviour Actors.SplitBrainDetector

  alias Actors.Exceptions.NetworkPartitionException

  @activated_status "ACTIVATED"

  @impl true
  def check_network_partition(status, node) do
    if status === @activated_status and node != Atom.to_string(Node.self()) do
      {:error, :network_partition_detected}
    else
      {:ok, :continue}
    end
  end

  @impl true
  def check_network_partition!(status, node) do
    if status === @activated_status and node != Atom.to_string(Node.self()) do
      raise NetworkPartitionException
    end
  end
end
