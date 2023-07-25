defmodule Actors.Node.NetworkPartitionDetector do
  @moduledoc false
  alias Actors.Exceptions.NetworkPartitionException

  @activated_status "ACTIVATED"
  @self Atom.to_string(Node.self())

  def check_network_partition(status, node) do
    if status === @activated_status and node != @self do
      {:error, :network_partition_detected}
    else
      {:ok, :continue}
    end
  end

  def check_network_partition!(status, node) do
    if status === @activated_status and node != Atom.to_string(Node.self()) do
      raise NetworkPartitionException
    end
  end
end
