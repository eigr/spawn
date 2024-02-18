defmodule Actors.Node.Client do
  @moduledoc """
  `Node.Client` Uses the HTTP interface to communicate with the application
  that owns the ActorHosts.
  """

  alias Actors.Config.PersistentTermConfig, as: Config
  import Spawn.Utils.Common, only: [to_existing_atom_or_new: 1]

  @actor_invoke_uri "/api/v1/actors/actions"

  @headers [
    {"Connection", "keep-alive"},
    {"content-type", "application/octet-stream"}
  ]

  @req_timeout 60_000

  def invoke_host_actor(body, opts \\ []) do
    with {:ok, client} <- client(body, opts) do
      # seems useless but Finch doesn't have the request timeout spec specified
      opts = Keyword.merge([], request_timeout: @req_timeout, receive_timeout: @req_timeout)

      Finch.request(client, SpawnHTTPClient, opts)
    end
  end

  defp client(body, opts) do
    with {:ok, base_url} <- base_url(get_deployment_mode(), opts) do
      {:ok, Finch.build(:post, "#{base_url}#{@actor_invoke_uri}", @headers, body)}
    else
      error -> error
    end
  end

  defp base_url(:sidecar, _opts) do
    {:ok, "http://#{Config.get(:user_function_host)}:#{Config.get(:user_function_port)}"}
  end

  defp base_url(:daemon, opts) do
    with {:ok, host} <- Keyword.fetch(opts, :remote_ip) do
      {:ok, "http://#{host}:8090"}
    else
      _ -> {:error, "Missing required :remote_ip option for daemon mode"}
    end
  end

  defp get_deployment_mode() do
    Config.get(:deployment_mode)
    |> to_existing_atom_or_new()
  end
end
