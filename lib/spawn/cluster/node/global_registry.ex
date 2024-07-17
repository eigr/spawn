defmodule Spawn.Cluster.Node.GlobalRegistry do
  @moduledoc """

  """
  use GenServer

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  def init(state) do
    {:ok, state}
  end
end
