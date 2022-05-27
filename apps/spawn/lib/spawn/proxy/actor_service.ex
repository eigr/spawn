defmodule Spawn.Proxy.ActorService do
  use GRPC.Server, service: Eigr.Functions.Protocol.ActorService.Service
  require Logger

  alias Eigr.Functions.Protocol.Actors.{Actor, ActorEntity, ActorSystem, Registry}
  alias Eigr.Functions.Protocol.Actors.ActorEntity.Supervisor, as: ActorEntitySupervisor

  alias Eigr.Functions.Protocol.{
    ActorInvocation,
    ActorSystemRequest,
    ActorSystemResponse,
    InvocationRequest,
    InvocationResponse,
    RegistrationRequest,
    RegistrationResponse,
    ServiceInfo
  }

  alias Spawn.Proxy.NodeManager
  alias Spawn.Proxy.NodeManager.Supervisor, as: NodeManagerSupervisor

  alias Spawn.Registry.ActorRegistry

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
        create_actors(actors)

      reason ->
        Logger.error("Failed to spawn actor system: #{inspect(reason)}")
    end
  end

  defp handle(
         {:invocation_request,
          %InvocationRequest{
            actor: %Actor{name: actor_name, system: %ActorSystem{name: system_name}} = actor,
            async: invocation_type
          } = request} = _message,
         stream
       ) do
    Logger.debug("Invocation request received: #{inspect(request)}")
    invoke(invocation_type, actor, request, stream)
  end

  defp handle(
         {:actor_invocation_response, %ActorInvocation{} = actor_invocation_response} = _message,
         stream
       ) do
    Logger.debug("Actor invocation response received: #{inspect(actor_invocation_response)}")
  end

  defp create_actors(actors) do
    Enum.each(actors, fn {actor_name, actor} ->
      Logger.debug(
        "Registering #{actor_name}: #{inspect(actor)} on Node: #{inspect(Node.self())}"
      )

      case ActorEntitySupervisor.lookup_or_create_actor(actor) do
        {:ok, pid} ->
          Logger.debug("Registered Actor #{actor_name} with pid: #{pid}")

        _ ->
          Logger.debug("Failed to register Actor #{actor_name}")
      end
    end)
  end

  defp invoke(
         false,
         %Actor{name: actor_name, system: %ActorSystem{name: system_name}} = actor,
         request,
         stream
       ) do
    with {:ok, %{node: node, actor: registered_actor}} <-
           ActorRegistry.lookup(system_name, actor_name),
         pid <- Node.spawn(node, NodeManager, :try_reactivate, [system_name, actor]) do
      ActorEntity.invoke_sync(actor_name, request)
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
         %Actor{name: actor_name, system: %ActorSystem{name: system_name}} = actor,
         request,
         stream
       ) do
    with {:ok, %{node: node, actor: registered_actor}} <-
           ActorRegistry.lookup(system_name, actor_name),
         pid <- Node.spawn(node, NodeManager, :try_reactivate, [system_name, actor]) do
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
