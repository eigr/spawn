defmodule Actors.Node.Adapters.ErqwestAdapter do
  @moduledoc """
  Tesla adapter using erqwest http client library
  """
  @behaviour Tesla.Adapter

  @impl Tesla.Adapter
  def call(%Tesla.Env{} = env, opts) do
    name = Keyword.fetch!(opts, :name)
    opts = Tesla.Adapter.opts(env, opts)
    url = Tesla.build_url(env.url, env.query)

    case request(name, env.method, url, env.headers, env.body, opts) do
      {:ok, %{status: status, body: body, headers: headers}} ->
        {:ok, %Tesla.Env{env | status: status, headers: headers, body: body}}

      error ->
        {:error, Exception.message(error)}
    end
  end

  defp request(name, method, url, headers, body, _opts) do
    case method do
      :post ->
        :erqwest.post(name, url, %{body: body, headers: headers})

      _ ->
        raise ArgumentError, "Method not supported #{inspect(method)}"
    end
  end
end
