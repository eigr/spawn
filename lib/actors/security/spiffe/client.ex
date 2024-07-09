defmodule Actors.Security.Spiffe.Client do
  use GRPC.Stub, service: Spiffe.Workload.SpiffeWorkloadAPI.Service

  alias Actors.Config.PersistentTermConfig, as: Config

  alias Spiffe.Workload.JWTSVIDRequest
  alias Spiffe.Workload.X509SVIDRequest
  alias Spiffe.Workload.ValidateJWTSVIDRequest

  alias Spiffe.Workload.SpiffeWorkloadAPI.Stub, as: SpiffeStub

  def fetch_x509_svid() do
    # Replace with your SPIRE server address
    url =
      "#{Config.get(:security_idp_spire_server_address)}:#{Config.get(:security_idp_spire_server_port)}"

    with {:connect, {:ok, channel}} <- {:connect, GRPC.Stub.connect(url)},
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
    # Replace with your SPIRE server address
    {:ok, channel} = GRPC.Stub.connect("localhost:8081")
    request = %JWTSVIDRequest{audience: audience, spiffe_id: spiffe_id}
    SpiffeStub.fetch_jwtsvid(channel, request)
  end

  def validate_jwt_svid(audience, svid) do
    # Replace with your SPIRE server address
    {:ok, channel} = GRPC.Stub.connect("localhost:8081")
    request = %ValidateJWTSVIDRequest{audience: audience, svid: svid}
    SpiffeStub.validate_jwtsvid(channel, request)
  end
end
