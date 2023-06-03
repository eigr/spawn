defmodule Actors.Node.Client do
  @moduledoc """
  `Node.Client` Uses the HTTP interface to communicate with the application
  that owns the ActorHosts.
  """
  use Tesla

  alias Actors.Config.Vapor, as: Config

  import Spawn.Utils.Common, only: [to_existing_atom_or_new: 1]

  @actor_invoke_uri "/api/v1/actors/actions"

  plug(
    Tesla.Middleware.BaseUrl,
    "http://#{Config.get(Actors, :user_function_host)}:#{Config.get(Actors, :user_function_port)}"
  )

  plug(Tesla.Middleware.Headers, [
    {"Connection", "keep-alive"},
    {"content-type", "application/octet-stream"}
  ])

  plug(Tesla.Middleware.Logger)

  def invoke_host_actor(req, opts \\ [])

  def invoke_host_actor(req, opts) do
    case get_deployment_mode() do
      :sidecar ->
        post(@actor_invoke_uri, req)

      :daemon ->
        Tesla.post(client(opts), @actor_invoke_uri, req)

      unknown ->
        raise ArgumentError,
              "Unknown Deployment Mode. Valid :sidecar or :daemon, found #{inspect(unknown)}"
    end
  end

  defp client(opts) do
    middleware = [
      {Tesla.Middleware.BaseUrl, get_host_address(get_deployment_mode(), opts)},
      {Tesla.Middleware.Headers, [{"content-type", "application/octet-stream"}]},
      Tesla.Middleware.Logger
    ]

    Tesla.client(middleware)
  end

  defp get_deployment_mode() do
    Config.get(Actors, :deployment_mode)
    |> to_existing_atom_or_new()
  end

  defp get_host_address(:sidecar, _opts) do
    "#{get_protocol()}://#{Config.get(Actors, :user_function_host)}:#{Config.get(Actors, :user_function_port)}"
  end

  defp get_host_address(:daemon, opts) do
    host = Keyword.fetch!(opts, :remote_ip)
    "#{get_protocol()}://#{host}:8090"
  end

  defp get_protocol() do
    "http"
  end
end
