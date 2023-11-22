defmodule Proxy.Supervisor do
  @moduledoc """
  Proxy Application Root Supervisor.
  """
  use Supervisor

  alias Actors.Config.PersistentTermConfig, as: Config

  @shutdown_timeout_ms 390_000

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      # wait up to 6,5 minutes to stop
      shutdown: @shutdown_timeout_ms
    }
  end

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    children = [
      {Sidecar.Supervisor, opts},
      {Bandit, get_bandit_options(opts)}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp get_bandit_options(opts) do
    if Config.get(:proxy_uds_enable) do
      get_uds_options(opts)
    else
      get_tcp_options(opts)
    end
    |> Keyword.merge(plug: Proxy.Router, scheme: :http)
  end

  defp get_uds_options(_opts) do
    [
      port: 0,
      thousand_island_options: [
        transport_options: [ip: {:local, Config.get(:proxy_sock_addr)}]
      ]
    ]
  end

  defp get_tcp_options(_opts) do
    [
      port: Config.get(:http_port),
      thousand_island_options: [
        num_acceptors: 150,
        max_connections_retry_wait: 2000,
        max_connections_retry_count: 10,
        shutdown_timeout: 120_000
      ]
    ]
  end
end
