defmodule Spawn.Proxy.Endpoint do
  use GRPC.Endpoint

  intercept(GRPC.Logger.Server)

  run(Spawn.Proxy.ActorService)
end
