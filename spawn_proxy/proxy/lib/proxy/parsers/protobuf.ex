defmodule Proxy.Parsers.Protobuf do
  @moduledoc """
  Parser for Protobuf format
  """
  @behaviour Plug.Parsers

  @impl true
  def init(opts), do: opts

  @impl true
  def parse(conn, "application", "protobuf", _headers, opts), do: read_body(conn, opts)

  def parse(conn, "application", "octet-stream", _headers, opts), do: read_body(conn, opts)

  def parse(conn, _type, _subtpe, _headers, _opts), do: {:next, conn}

  defp read_body(conn, opts) do
    {:ok, body, conn} = Plug.Conn.read_body(conn, opts)
    {:ok, %{"_proto" => body}, conn}
  end
end
