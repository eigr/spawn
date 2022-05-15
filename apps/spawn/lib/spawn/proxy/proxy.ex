defmodule Spawn.Proxy do
  use GenServer
  require Logger

  alias Eigr.Functions.Protocol.ActorService.Stub, as: ActorServiceClient

  defmodule StreamLoopController do
    def receive(proxy_pid, stream) do
      Stream.each(stream, fn ->
        send(proxy_pid, {})
      end)
    end
  end

  @spec init(any) :: {:ok, any, {:continue, :connect}}
  def init(state) do
    {:ok, state, {:continue, :connect}}
  end

  @spec handle_continue(:connect, any) :: {:noreply, any}
  def handle_continue(:connect, state) do
    proxy_pid = self()

    with {:ok, channel} <- get_connection() do
      stream = ActorServiceClient.spawn(channel)
      Logger.debug("Initializing Actor Service...")
      spawn(StreamLoopController, :receive, [proxy_pid, stream])
      {:noreply, state}
    else
      {:error, reason} -> raise reason
    end

    {:noreply, state}
  end

  defp get_connection(),
    do:
      GRPC.Stub.connect(get_address(is_uds_enable?()),
        interceptors: [GRPC.Logger.Client],
        adapter_opts: %{http2_opts: %{keepalive: 10000}}
      )

  defp get_uds_address(),
    do: Application.get_env(:spawn_proxy, :user_function_sock_addr, "/var/run/spawn.sock")

  defp is_uds_enable?(),
    do: Application.get_env(:spawn_proxy, :user_function_uds_enable, false)

  defp get_function_host(),
    do: Application.get_env(:spawn_proxy, :user_function_host, "127.0.0.1")

  defp get_function_port(), do: Application.get_env(:spawn_proxy, :user_function_port, 8080)

  def get_address(false), do: "#{get_function_host()}:#{get_function_port()}"

  def get_address(true), do: "#{get_uds_address()}"
end
