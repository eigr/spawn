defmodule Actors.Node.DefaultSplitBrainDetector do
  @moduledoc false
  @behaviour Actors.SplitBrainDetector

  alias Actors.Exceptions.NetworkPartitionException

  @activated_status "ACTIVATED"

  @impl true
  def check_network_partition(actor_id, status, node) do
    if do_check(actor_id, status, node) do
      {:error, :network_partition_detected}
    else
      {:ok, :continue}
    end
  end

  @impl true
  def check_network_partition!(actor_id, status, node) do
    if do_check(actor_id, status, node) do
      raise NetworkPartitionException
    end
  end

  defp do_check(actor_id, status, node) do
    host_actor_found? =
      actor_id
      |> Spawn.Cluster.StateHandoff.Manager.get()
      |> Enum.find_value(false, &(&1.node == Node.self()))

    status === @activated_status and node != Atom.to_string(Node.self()) and not host_actor_found?
  end
end
