defmodule Actors.Security.Spiffe.Client do
  use GRPC.Stub, service: Spiffe.Workload.SpiffeWorkloadAPI.Service

  alias Actors.Config.PersistentTermConfig, as: Config

  alias Spiffe.Workload.JWTSVIDRequest
  alias Spiffe.Workload.X509SVIDRequest
  alias Spiffe.Workload.ValidateJWTSVIDRequest

  alias Spiffe.Workload.SpiffeWorkloadAPI.Stub, as: SpiffeStub

  def fetch_x509_svid() do
    with {:connect, {:ok, channel}} <-
           {:connect,
            GRPC.Stub.connect(build_url(),
              headers: [{"workload.spiffe.io", "true"}],
              adapter_opts: [
                http2_opts: %{settings_timeout: 10_000},
                retry: 5,
                retry_fun: &retry_fun/2
              ]
            )},
         {:build_request, request} <- {:build_request, %X509SVIDRequest{}} do
      SpiffeStub.fetch_x509_svid(channel, request)
    else
      {:connect, error} ->
        {:error, error}

      {:build_request, error} ->
        {:error, error}
    end
  end

  def fetch_jwt_svid(audience, spiffe_id \\ nil) do
    with {:connect, {:ok, channel}} <- {:connect, GRPC.Stub.connect(build_url())},
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
    with {:connect, {:ok, channel}} <- {:connect, GRPC.Stub.connect(build_url())},
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

  defp build_url(),
    do:
      "#{Config.get(:security_idp_spire_server_address)}:#{Config.get(:security_idp_spire_server_port)}"

  defp retry_fun(_reason, _attempt) do
    :ok
  end
end
