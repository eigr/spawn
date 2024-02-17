defmodule Sidecar.Grpc.Dispatcher do
  @moduledoc false
  require Logger

  def dispatch(
        %{
          system: system_name,
          actor: actor_name,
          input: message,
          stream: stream,
          descriptor: descriptor
        } = request
      ) do
    Logger.debug(
      "Dispatching gRPC message to actor #{system_name}:#{actor_name}. Params: #{inspect(request)}"
    )
  end
end
