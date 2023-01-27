defmodule Spawn.Cluster.Epmd.Client do
  @moduledoc """
  Implementation of the `epmd` client logic. Meant for use with the `-epmd_module` flag.
  It will return a port from `Caravan.Epmd.dist_port/1` as opposed to calling
  out to the `epmd` daemon and having it assign us one.
  """
  alias Spawn.Cluster.Epmd

  # erl_distribution wants us to start a worker process.  We don't
  # need one, though.
  def start_link do
    :ignore
  end

  # As of Erlang/OTP 19.1, register_node/3 is used instead of
  # register_node/2, passing along the address family, 'inet_tcp' or
  # 'inet6_tcp'.  This makes no difference for our purposes.
  def register_node(name, port, _family) do
    register_node(name, port)
  end

  def register_node(_name, _port) do
    # This is where we would connect to epmd and tell it which port
    # we're listening on, but since we're epmd-less, we don't do that.

    # Need to return a "creation" number between 1 and 3.
    creation = :rand.uniform(3)
    {:ok, creation}
  end

  def port_please(name, _ip) do
    port = Epmd.dist_port(name)
    # The distribution protocol version number has been 5 ever since
    # Erlang/OTP R6.
    version = 5
    {:port, port, version}
  end

  # added for OTP-21
  def address_please(_name, host, _address_family) do
    :inet.getaddr(host, :inet)
  end

  def names(_hostname) do
    # Since we don't have epmd, we don't really know what other nodes
    # there are.
    {:error, :address}
  end
end
