defmodule Actors do
  @moduledoc """
  Documentation for `Spawn`.
  """
  require Logger

  alias Actors.Actor.Entity, as: ActorEntity
  alias Actors.Actor.Entity.Supervisor, as: ActorEntitySupervisor

  alias Actors.Registry.ActorRegistry

  alias Eigr.Functions.Protocol.Actors.{Actor, ActorId, ActorSystem, Registry}

  alias Eigr.Functions.Protocol.{
    InvocationRequest,
    ProxyInfo,
    RegistrationRequest,
    RegistrationResponse,
    ServiceInfo
  }

  @activate_actors_min_demand 0
  @activate_actors_max_demand 4

  def register(
        %RegistrationRequest{
          service_info: %ServiceInfo{} = _service_info,
          actor_system:
            %ActorSystem{name: _name, registry: %Registry{actors: actors} = _registry} =
              _actor_system
        } = _registration
      ) do
    ActorRegistry.register(actors)

    with :ok <- create_actors(actors) do
      proxy_info =
        ProxyInfo.new(
          protocol_major_version: 1,
          protocol_minor_version: 2,
          proxy_name: "spawn",
          proxy_version: "0.1.0"
        )

      # Start Activators here

      # Then response to the caller
      {:ok, RegistrationResponse.new(proxy_info: proxy_info)}
    end
  end

  def get_state(system_name, actor_name) do
    case Actors.Actor.Registry.lookup(actor_name) do
      [{pid, nil}] ->
        Logger.debug("Lookup Actor #{actor_name}. PID: #{inspect(pid)}")
        # This return {:ok, response_body}
        ActorEntity.get_state(actor_name)

      _ ->
        with {:ok, %{node: node, actor: actor}} <-
               ActorRegistry.lookup(system_name, actor_name),
             _pid <- Node.spawn(node, __MODULE__, :try_reactivate_actor, [nil, actor]) do
          Process.sleep(1)
          {:ok, response_body} = ActorEntity.get_state(actor_name)

          {:ok, response_body}
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

  def invoke(
        %InvocationRequest{
          actor_id: %ActorId{} = actor,
          async: type
        } = request
      ) do
    invoke(type, actor, request)
  end

  defp invoke(
         false,
         %ActorId{name: actor_name, actor_system: system_name} = _actor_id,
         request
       ) do
    case Actors.Actor.Registry.lookup(actor_name) do
      [{pid, nil}] ->
        Logger.debug("Lookup Actor #{actor_name}. PID: #{inspect(pid)}")
        # This return {:ok, response_body}
        ActorEntity.invoke(actor_name, request)

      _ ->
        with {:ok, %{node: node, actor: registered_actor}} <-
               ActorRegistry.lookup(system_name, actor_name),
             _pid <-
               Node.spawn(node, __MODULE__, :try_reactivate_actor, [registered_actor]) do
          Process.sleep(1)
          {:ok, response_body} = ActorEntity.invoke(actor_name, request)

          {:ok, response_body}
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

  defp invoke(
         true,
         %ActorId{name: actor_name, actor_system: system_name} = _actor_id,
         request
       ) do
    case Actors.Actor.Registry.lookup(actor_name) do
      [{pid, nil}] ->
        Logger.debug("Lookup Actor #{actor_name}. PID: #{inspect(pid)}")
        # This return {:ok, response_body}
        ActorEntity.invoke(actor_name, request)

      _ ->
        with {:ok, %{node: node, actor: registered_actor}} <-
               ActorRegistry.lookup(system_name, actor_name),
             _pid <-
               Node.spawn(node, __MODULE__, :try_reactivate_actor, [registered_actor]) do
          Process.sleep(1)
          {:ok, response_body} = ActorEntity.invoke_async(actor_name, request)

          {:ok, response_body}
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

  def try_reactivate_actor(%Actor{actor_id: %ActorId{name: name}} = actor) do
    case ActorEntitySupervisor.lookup_or_create_actor(actor) do
      {:ok, pid} ->
        Logger.debug("Actor #{name} reactivated. PID: #{inspect(pid)}")
        {:ok, pid}

      reason ->
        Logger.error("Failed to reactivate actor #{name}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp create_actors(actors) do
    actors
    |> Flow.from_enumerable(
      min_demand: @activate_actors_min_demand,
      max_demand: @activate_actors_max_demand
    )
    |> Flow.map(fn {actor_name, actor} ->
      Logger.debug("Registering #{actor_name} #{inspect(actor)} on Node: #{inspect(Node.self())}")

      {time, result} = :timer.tc(&lookup_actor/2, [actor_name, actor])

      Logger.info(
        "Registered and Activated the #{actor_name} on Node #{inspect(Node.self())} in #{inspect(time)}ms"
      )

      result
    end)
    |> Flow.run()
  end

  defp lookup_actor(actor_name, actor) do
    case ActorEntitySupervisor.lookup_or_create_actor(actor) do
      {:ok, pid} ->
        {:ok, pid}

      error ->
        Logger.debug("Failed to register Actor #{actor_name}")
        {:error, error}
    end
  end
end
