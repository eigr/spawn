defmodule Spawn.Proxy.ActorService do
  use GRPC.Server,
    service: Eigr.Functions.Protocol.ActorService.Service,
    compressors: [GRPC.Compressor.Gzip]

  require Logger

  alias Eigr.Functions.Protocol.Actors.{Actor, ActorEntity, ActorSystem, Registry}
  alias Eigr.Functions.Protocol.Actors.ActorEntity.Supervisor, as: ActorEntitySupervisor

  alias Eigr.Functions.Protocol.{
    ActorInvocation,
    ActorInvocationResponse,
    ActorSystemRequest,
    ActorSystemResponse,
    InvocationRequest,
    InvocationResponse,
    ProxyInfo,
    RegistrationRequest,
    RegistrationResponse,
    ServiceInfo
  }

  alias Spawn.Proxy.NodeManager
  alias Spawn.Proxy.NodeManager.Supervisor, as: NodeManagerSupervisor

  alias Spawn.Registry.ActorRegistry

  @activate_actors_min_demand 0
  @activate_actors_max_demand 4

  @spec spawn(ActorSystemRequest.t(), GRPC.Server.Stream.t()) :: ActorSystemResponse.t()
  def spawn(messages, stream) do
    messages
    |> Stream.each(fn %ActorSystemRequest{message: message} -> handle(message, stream) end)
    |> Stream.run()
  end

  defp handle(
         {:registration_request,
          %RegistrationRequest{
            service_info: %ServiceInfo{} = service_info,
            actor_system:
              %ActorSystem{name: name, registry: %Registry{actors: actors} = registry} =
                actor_system
          } = registration} = _message,
         stream
       ) do
    Logger.debug("Registration request received: #{inspect(registration)}")

    ActorRegistry.register(actors)

    case NodeManagerSupervisor.create_connection_manager(%{
           actor_system: name,
           source_stream: stream
         }) do
      {:ok, pid} ->
        create_actors(actor_system, actors)

        GRPC.Server.send_reply(
          stream,
          RegistrationResponse.new(proxy_info: ProxyInfo.new())
        )

      reason ->
        Logger.error("Failed to spawn actor system: #{inspect(reason)}")
    end
  end

  defp handle(
         {:invocation_request,
          %InvocationRequest{
            actor: %Actor{} = actor,
            system: %ActorSystem{} = system,
            async: invocation_type
          } = request} = _message,
         stream
       ) do
    Logger.debug("Invocation request received: #{inspect(request)}")
    invoke(invocation_type, system, actor, request, stream)
  end

  defp handle(
         {:actor_invocation_response, %ActorInvocationResponse{} = actor_invocation_response} =
           _message,
         stream
       ) do
    Logger.debug("Actor invocation response received: #{inspect(actor_invocation_response)}")
  end

  defp create_actors(actor_system, actors) do
    actors
    |> Flow.from_enumerable(
      min_demand: @activate_actors_min_demand,
      max_demand: @activate_actors_max_demand
    )
    |> Flow.map(fn {actor_name, actor} ->
      Logger.debug("Registering #{actor_name} #{inspect(actor)} on Node: #{inspect(Node.self())}")

      {time, result} = :timer.tc(&lookup_actor/3, [actor_system, actor_name, actor])

      Logger.info(
        "Registered and Activated the #{actor_name} on Node #{inspect(Node.self())} in #{inspect(time)}ms"
      )

      result
    end)
    |> Flow.run()
  end

  defp lookup_actor(actor_system, actor_name, actor) do
    case ActorEntitySupervisor.lookup_or_create_actor(actor_system, actor) do
      {:ok, pid} ->
        {:ok, pid}

      error ->
        Logger.debug("Failed to register Actor #{actor_name}")
        {:error, error}
    end
  end

  defp send_actor_invocation_response() do
  end

  defp invoke(
         false,
         %ActorSystem{name: system_name} = system,
         %Actor{name: actor_name} = actor,
         request,
         stream
       ) do
    with {:ok, %{node: node, actor: registered_actor}} <-
           ActorRegistry.lookup(system_name, actor_name),
         _pid <- Node.spawn(node, NodeManager, :try_reactivate_actor, [system, actor]) do
      ActorEntity.invoke(actor_name, request)
    else
      {:not_found, _} ->
        Logger.error("Actor #{actor_name} not found on ActorSystem #{system_name}")
        {:error, "Actor #{actor_name} not found on ActorSystem #{system_name}"}

      {:error, reason} ->
        Logger.error(
          "Failed to invoke Actor #{actor_name} on ActorSystem #{system_name}: #{inspect(reason)}"
        )

        {:error, reason}

      _ ->
        Logger.error("Failed to invoke Actor #{actor_name} on ActorSystem #{system_name}")
        {:error, "Failed to invoke Actor #{actor_name} on ActorSystem #{system_name}"}
    end
  end

  defp invoke(
         true,
         %ActorSystem{name: system_name} = system,
         %Actor{name: actor_name} = actor,
         request,
         stream
       ) do
    with {:ok, %{node: node, actor: registered_actor}} <-
           ActorRegistry.lookup(system_name, actor_name),
         pid <- Node.spawn(node, NodeManager, :try_reactivate_actor, [system, actor]) do
      ActorEntity.invoke_async(actor_name, request)
    else
      {:not_found, _} ->
        Logger.error("Actor #{actor_name} not found on ActorSystem #{system_name}")
        {:error, "Actor #{actor_name} not found on ActorSystem #{system_name}"}

      {:error, reason} ->
        Logger.error(
          "Failed to invoke Actor #{actor_name} on ActorSystem #{system_name}: #{inspect(reason)}"
        )

        {:error, reason}

      _ ->
        Logger.error("Failed to invoke Actor #{actor_name} on ActorSystem #{system_name}")
        {:error, "Failed to invoke Actor #{actor_name} on ActorSystem #{system_name}"}
    end
  end
end
