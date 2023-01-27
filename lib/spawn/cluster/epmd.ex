defmodule Spawn.Cluster.Epmd do
  @moduledoc """
  Shared logic for determining the Erlang distribution port from the node name.

  ### Examples
  iex --erl "-proto_dist Elixir.Spawn.Cluster.Epmd.Dist -start_epmd false -epmd_module Elixir.Spawn.Cluster.Epmd.Client" --sname "proxy" -S mix
  """

  @doc """
  Returns the Erlang Distribution port based on a node name.
  ### Examples
      iex> Spawn.Cluster.Epmd.dist_port(:"app-name@example.net")
      4370
  """
  def dist_port(_name) do
    System.get_env("PROXY_CLUSTER_EPMD_PORT", "4370")
    |> String.to_integer()
  end
end
