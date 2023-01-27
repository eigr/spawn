defmodule Spawn.Cluster.Epmd.Dist_dist do
  @moduledoc """
  `Dist_dist` Implements the Erlang distribution protocol without EPMD process.
  The `_dist` part of the module name is required for it to work,
  but will be used like this `-proto_dist Spawn.Cluster.Epmd.Dist`
  """

  alias Spawn.Cluster.Epmd

  def listen(name) do
    port = Epmd.dist_port(name)

    # Set both "min" and "max" variables, to force the port number to
    # this one.
    :ok = :application.set_env(:kernel, :inet_dist_listen_min, port)
    :ok = :application.set_env(:kernel, :inet_dist_listen_max, port)

    # Delegate to real distribution protocol
    :inet_tcp_dist.listen(name)
  end

  def select(node) do
    :inet_tcp_dist.select(node)
  end

  def accept(listen) do
    :inet_tcp_dist.accept(listen)
  end

  def accept_connection(accept_pid, socket, my_node, allowed, setup_time) do
    :inet_tcp_dist.accept_connection(accept_pid, socket, my_node, allowed, setup_time)
  end

  def setup(node, type, my_node, long_or_short_names, setup_time) do
    :inet_tcp_dist.setup(node, type, my_node, long_or_short_names, setup_time)
  end

  def close(listen) do
    :inet_tcp_dist.close(listen)
  end

  def is_node_name(node) do
    :inet_tcp_dist.is_node_name(node)
  end
end
