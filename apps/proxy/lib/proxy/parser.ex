defmodule Proxy.Parser do
  @behaviour Plug.Parsers

  @impl true
  def init(opts), do: opts

  @impl true
  def parse(conn, "application", "octet-stream", _headers, opts) do
    {:ok, body, conn} = Plug.Conn.read_body(conn, opts)
    {:ok, %{"_proto" => body}, conn}
  end
end
