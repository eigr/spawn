defmodule Actors.Security.Spiffe.Client do
  use GRPC.Stub, service: SpiffeWorkloadAPI.Service
  require Logger

  alias Actors.Config.PersistentTermConfig, as: Config

  alias JWTSVIDRequest
  alias X509SVIDRequest
  alias ValidateJWTSVIDRequest

  alias SpiffeWorkloadAPI.Stub, as: SpiffeStub

  def fetch_x509_svid() do
    with {:build_url, url} <- {:build_url, build_url()},
         {:connect, {:ok, channel}} <- {:connect, connect(url)},
         {:build_request, request} <- {:build_request, %X509SVIDRequest{}} do
      case SpiffeStub.fetch_x509_svid(channel, request) do
        {:ok, res_stream} ->
          Enum.map(res_stream, fn item ->
            IO.inspect(item)
          end)

        {:error, error} ->
          Logger.error("Error during request. Detail: #{inspect(error)}")
          {:error, error}
      end
    else
      {:connect, error} ->
        Logger.error("Error to obtain a connection. Detail: #{inspect(error)}")
        {:error, error}

      {:build_request, error} ->
        Logger.error("Error during request. Detail: #{inspect(error)}")
        {:error, error}
    end
  end

  def fetch_jwt_svid(audience, spiffe_id \\ nil) do
    with {:build_url, url} <- {:build_url, build_url()},
         {:connect, {:ok, channel}} <- {:connect, connect(url)},
         {:build_request, request} <-
           {:build_request, %JWTSVIDRequest{audience: audience, spiffe_id: spiffe_id}} do
      SpiffeStub.fetch_jwtsvid(channel, request)
    else
      {:connect, error} ->
        {:error, error}

      {:build_request, error} ->
        {:error, error}
    end
  end

  def validate_jwt_svid(audience, svid) do
    with {:build_url, url} <- {:build_url, build_url()},
         {:connect, {:ok, channel}} <- {:connect, connect(url)},
         {:build_request, request} <-
           {:build_request, %ValidateJWTSVIDRequest{audience: audience, svid: svid}} do
      SpiffeStub.validate_jwtsvid(channel, request)
    else
      {:connect, error} ->
        {:error, error}

      {:build_request, error} ->
        {:error, error}
    end
  end

  defp connect(url) do
    GRPC.Stub.connect(url,
      adapter: GRPC.Client.Adapters.Mint,
      headers: [{"workload.spiffe.io", "true"}],
      adapter_opts: [
        http2_opts: %{settings_timeout: :infinity},
        retry: 5,
        retry_fun: &retry_fun/2
      ],
      client_settings: [
        initial_window_size: 8_000_000,
        max_frame_size: 8_000_000
      ],
      transport_opts: [timeout: :infinity],
      interceptors: [{Actors.Security.Spiffe.LoggerInterceptor, level: :debug}]
    )
  end

  defp build_url(),
    do:
      "http://#{Config.get(:security_idp_spire_server_address)}:#{Config.get(:security_idp_spire_server_port)}"

  defp retry_fun(_reason, _attempt) do
    :ok
  end
end
