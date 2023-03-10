defmodule Spawn.Cluster.Node.Server do
  use Gnat.Server

  def request(%{body: _body}) do
    {:reply, ""}
  end

  def error(%{gnat: gnat, reply_to: reply_to}, _error) do
    # TODO handle errors
    # Gnat.pub(gnat, reply_to, "Something went wrong and I can't handle your request")
  end
end
