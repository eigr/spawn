defmodule Actors do
  @moduledoc """
  Documentation for `Spawn`.
  """
  require Logger

  alias Actors.Actor.Entity, as: ActorEntity
  alias Actors.Actor.Entity.Supervisor, as: ActorEntitySupervisor

  alias Actors.Registry.{ActorRegistry, Member, Host}

  alias Eigr.Functions.Protocol.Actors.{Actor, ActorSystem, Registry}

  alias Eigr.Functions.Protocol.{
    InvocationRequest,
    ProxyInfo,
    RegistrationRequest,
    RegistrationResponse,
    RequestStatus,
    ServiceInfo,
    SpawnRequest,
    SpawnResponse
  }

  @activate_actors_min_demand 0
  @activate_actors_max_demand 4

  @erpc_timeout 5_000

  @spec get_state(String.t(), String.t()) :: {:ok, term()} | {:error, term()}
  def get_state(system_name, actor_name) do
    do_lookup_action(system_name, actor_name, nil, fn actor_ref ->
      ActorEntity.get_state(actor_ref)
    end)
  end

  @spec register(RegistrationRequest.t(), any()) :: {:ok, RegistrationResponse.t()}
  def register(registration, opts \\ [])

  def register(
        %RegistrationRequest{
          service_info: %ServiceInfo{} = _service_info,
          actor_system:
            %ActorSystem{name: _name, registry: %Registry{actors: actors} = _registry} =
              actor_system
        } = _registration,
        opts
      ) do
    member = %Member{
      id: Node.self(),
      host_function: %Host{actors: Map.values(actors), opts: opts}
    }

    ActorRegistry.register(member)

    spawn(fn ->
      create_actors(actor_system, actors, opts)
    end)

    proxy_info =
      ProxyInfo.new(
        protocol_major_version: 1,
        protocol_minor_version: 2,
        proxy_name: "spawn",
        proxy_version: "0.1.0"
      )

    status = RequestStatus.new(status: :OK, message: "Accepted")
    {:ok, RegistrationResponse.new(proxy_info: proxy_info, status: status)}
  end

  @spec spawn_actor(SpawnRequest.t(), any()) :: {:ok, SpawnResponse.t()}
  def spawn_actor(registration, opts \\ [])

  def spawn_actor(
        %SpawnRequest{
          actor_system:
            %ActorSystem{name: _name, registry: %Registry{actors: actors} = _registry} =
              actor_system
        } = _registration,
        opts
      ) do
    member = %Member{
      id: Node.self(),
      host_function: %Host{actors: Map.values(actors), opts: opts}
    }

    ActorRegistry.register(member)

    spawn(fn ->
      create_actors(actor_system, actors, opts)
    end)

    status = RequestStatus.new(status: :OK, message: "Accepted")
    {:ok, SpawnResponse.new(status: status)}
  end

  @spec invoke(%InvocationRequest{}) :: {:ok, :async} | {:ok, term()} | {:error, term()}
  def invoke(
        %InvocationRequest{
          actor: %Actor{} = actor,
          system: %ActorSystem{} = system,
          async: async?
        } = request,
        opts \\ []
      ) do
    do_lookup_action(system.name, actor.name, system, fn actor_ref ->
      maybe_invoke_async(async?, actor_ref, request, opts)
    end)
  end

  defp do_lookup_action(system_name, actor_name, system, action_fun) do
    case Spawn.Cluster.Node.Registry.lookup(Actors.Actor.Entity, actor_name) do
      [{actor_ref, _}] ->
        Logger.debug("Lookup Actor #{actor_name}. PID: #{inspect(actor_ref)}")

        action_fun.(actor_ref)

      _ ->
        with {:ok, %Member{id: node, host_function: %Host{actors: actors, opts: opts}}} <-
               ActorRegistry.lookup(system_name, actor_name) do
          actor = List.first(actors)

          {:ok, actor_ref} =
            :erpc.call(
              node,
              __MODULE__,
              :try_reactivate_actor,
              [system, actor, opts],
              @erpc_timeout
            )

          action_fun.(actor_ref)
        else
          {:not_found, _} ->
            Logger.error("Actor #{actor_name} not found on ActorSystem #{system_name}")
            {:error, "Actor #{actor_name} not found on ActorSystem #{system_name}"}

          {:erpc, :timeout} ->
            Logger.error(
              "Failed to invoke Actor #{actor_name} on ActorSystem #{system_name}: Node connection timeout"
            )

            {:error, "Node connection timeout"}

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

  defp maybe_invoke_async(true, actor_ref, request, opts) do
    ActorEntity.invoke_async(actor_ref, request, opts)

    {:ok, :async}
  end

  defp maybe_invoke_async(false, actor_ref, request, opts) do
    ActorEntity.invoke(actor_ref, request, opts)
  end

  @spec try_reactivate_actor(ActorSystem.t(), Actor.t(), any()) :: {:ok, any()} | {:error, any()}
  def try_reactivate_actor(system, actor, opts \\ [])

  def try_reactivate_actor(%ActorSystem{} = system, %Actor{name: name} = actor, opts) do
    case ActorEntitySupervisor.lookup_or_create_actor(system, actor, opts) do
      {:ok, actor_ref} ->
        Logger.debug("Actor #{name} reactivated. ActorRef PID: #{inspect(actor_ref)}")
        {:ok, actor_ref}

      reason ->
        Logger.error("Failed to reactivate actor #{name}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # To lookup all actors
  def try_reactivate_actor(nil, %Actor{name: name} = actor, opts) do
    case ActorEntitySupervisor.lookup_or_create_actor(nil, actor, opts) do
      {:ok, actor_ref} ->
        Logger.debug("Actor #{name} reactivated. ActorRef PID: #{inspect(actor_ref)}")
        {:ok, actor_ref}

      reason ->
        Logger.error("Failed to reactivate actor #{name}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp create_actors(actor_system, actors, opts) when is_map(actors) do
    actors
    |> Flow.from_enumerable(
      min_demand: @activate_actors_min_demand,
      max_demand: @activate_actors_max_demand
    )
    |> Flow.map(fn {actor_name, actor} ->
      Logger.debug("Registering #{actor_name} #{inspect(actor)} on Node: #{inspect(Node.self())}")

      {time, result} = :timer.tc(&lookup_actor/4, [actor_system, actor_name, actor, opts])

      Logger.info(
        "Registered and Activated the #{actor_name} on Node #{inspect(Node.self())} in #{inspect(time)}ms"
      )

      result
    end)
    |> Flow.run()
  end

  @spec lookup_actor(ActorSystem.t(), String.t(), Actor.t(), any()) ::
          {:ok, pid()} | {:error, String.t()}
  defp lookup_actor(actor_system, actor_name, actor, opts) do
    case ActorEntitySupervisor.lookup_or_create_actor(actor_system, actor, opts) do
      {:ok, pid} ->
        {:ok, pid}

      _ ->
        Logger.debug("Failed to register Actor #{actor_name}")
        {:error, "Failed to register Actor #{actor_name}"}
    end
  end
end
