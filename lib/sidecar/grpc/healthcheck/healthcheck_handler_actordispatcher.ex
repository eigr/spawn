defmodule Eigr.Functions.Protocol.Actors.Healthcheck.HealthCheckActor.ActorDispatcher do
  @moduledoc since: "1.2.1"
  use GRPC.Server,
    service: Eigr.Functions.Protocol.Actors.Healthcheck.HealthCheckActor.Service,
    http_transcode: true

  alias Sidecar.GRPC.Dispatcher

  @spec liveness(Google.Protobuf.Empty.t(), GRPC.Server.Stream.t()) ::
          Eigr.Functions.Protocol.Actors.Healthcheck.HealthCheckReply.t()
  def liveness(message, stream) do
    request = %{
      system: "spawn-system",
      actor_name: "HealthCheckActor",
      action_name: "Liveness",
      input: message,
      stream: stream,
      descriptor: Eigr.Functions.Protocol.Actors.Healthcheck.HealthCheckActor.Service.descriptor()
    }

    Dispatcher.dispatch(request)
  end

  @spec readiness(Google.Protobuf.Empty.t(), GRPC.Server.Stream.t()) ::
          Eigr.Functions.Protocol.Actors.Healthcheck.HealthCheckReply.t()
  def readiness(message, stream) do
    request = %{
      system: "spawn-system",
      actor_name: "HealthCheckActor",
      action_name: "Readiness",
      input: message,
      stream: stream,
      descriptor: Eigr.Functions.Protocol.Actors.Healthcheck.HealthCheckActor.Service.descriptor()
    }

    Dispatcher.dispatch(request)
  end
end
