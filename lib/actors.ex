defmodule Actors do
  @moduledoc """
  Documentation for `Actors`.
  """
  use Retry

  require Logger
  require OpenTelemetry.Tracer, as: Tracer

  alias Actors.Actor.Entity, as: ActorEntity
  alias Actors.Actor.Entity.Supervisor, as: ActorEntitySupervisor

  alias Actors.Registry.{ActorRegistry, HostActor}

  alias Eigr.Functions.Protocol.Actors.{Actor, ActorId, ActorSettings, ActorSystem, Registry}

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
    hosts =
      Enum.map(Map.values(actors), fn actor ->
        %HostActor{node: Node.self(), actor: actor, opts: opts}
      end)

    :ok = ActorRegistry.register(hosts)

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
              _actor_system
        } = _registration,
        opts
      ) do
    hosts =
      Enum.map(Map.values(actors), fn actor ->
        %HostActor{node: Node.self(), actor: actor, opts: opts}
      end)

    :ok = ActorRegistry.register(hosts)

    status = RequestStatus.new(status: :OK, message: "Accepted")
    {:ok, SpawnResponse.new(status: status)}
  end

  @spec invoke(%InvocationRequest{}) :: {:ok, :async} | {:ok, term()} | {:error, term()}
  def invoke(
        %InvocationRequest{} = request,
        opts \\ []
      ) do
    invoke_with_span(request)
  end

  defp invoke_with_span(
         %InvocationRequest{
           actor: %Actor{} = actor,
           system: %ActorSystem{} = system,
           async: async?
         } = request,
         opts \\ []
       ) do
    Tracer.with_span "invoke" do
      Tracer.add_event("invoke-actor", [{"target", actor.id.name}])
      Tracer.set_attributes([{:async, async?}])

      retry with: exponential_backoff() |> randomize |> expiry(10_000),
            atoms: [:error, :exit, :noproc, :erpc, :noconnection],
            rescue_only: [ErlangError] do
        do_lookup_action(system.name, actor.id.name, system, fn actor_ref ->
          maybe_invoke_async(async?, actor_ref, request, opts)
        end)
      after
        result -> result
      else
        error -> error
      end
    end
  end

  defp do_lookup_action(system_name, actor_name, system, action_fun) do
    Tracer.with_span "actor-lookup" do
      Tracer.set_attributes([{:system_name, system_name}])
      Tracer.set_attributes([{:actor_name, actor_name}])

      case Spawn.Cluster.Node.Registry.lookup(Actors.Actor.Entity, actor_name) do
        [{actor_ref, _}] ->
          Tracer.add_event("actor-status", [{"alive", true}])
          Tracer.set_attributes([{"actor-pid", "#{inspect(actor_ref)}"}])
          Logger.debug("Lookup Actor #{actor_name}. PID: #{inspect(actor_ref)}")

          action_fun.(actor_ref)

        _ ->
          Tracer.add_event("actor-status", [{"alive", false}])

          Tracer.with_span "actor-reactivation" do
            Tracer.set_attributes([{:system_name, system_name}])
            Tracer.set_attributes([{:actor_name, actor_name}])

            with {:ok, %HostActor{node: node, actor: actor, opts: opts}} <-
                   ActorRegistry.lookup(system_name, actor_name),
                 {:ok, actor_ref} =
                   :erpc.call(
                     node,
                     __MODULE__,
                     :try_reactivate_actor,
                     [system, actor, opts],
                     @erpc_timeout
                   ) do
              Tracer.set_attributes([{"actor-pid", "#{inspect(actor_ref)}"}])

              Tracer.add_event("try-reactivate-actor", [
                {"reactivation-on-node", "#{inspect(node)}"}
              ])

              action_fun.(actor_ref)
            else
              {:not_found, _} ->
                Logger.error("Actor #{actor_name} not found on ActorSystem #{system_name}")

                Tracer.add_event("reactivation-failure", [
                  {:cause, "not_found"}
                ])

                {:error, "Actor #{actor_name} not found on ActorSystem #{system_name}"}

              {:erpc, :timeout} ->
                Logger.error(
                  "Failed to invoke Actor #{actor_name} on ActorSystem #{system_name}: Node connection timeout"
                )

                Tracer.add_event("reactivation-failure", [
                  {:cause, "timeout"}
                ])

                {:error, "Node connection timeout"}

              {:error, reason} ->
                Logger.error(
                  "Failed to invoke Actor #{actor_name} on ActorSystem #{system_name}: #{inspect(reason)}"
                )

                Tracer.add_event("reactivation-failure", [
                  {:cause, "#{inspect(reason)}"}
                ])

                {:error, reason}

              _ ->
                Logger.error("Failed to invoke Actor #{actor_name} on ActorSystem #{system_name}")

                Tracer.add_event("reactivation-failure", [
                  {:cause, "unknown"}
                ])

                {:error, "Failed to invoke Actor #{actor_name} on ActorSystem #{system_name}"}
            end
          end
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

  def try_reactivate_actor(
        %ActorSystem{} = system,
        %Actor{id: %ActorId{name: name} = _id} = actor,
        opts
      ) do
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
  def try_reactivate_actor(nil, %Actor{id: %ActorId{name: name} = _id} = actor, opts) do
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
    |> Flow.filter(fn {_actor_name,
                       %Actor{
                         settings: %ActorSettings{persistent: persistent, abstract: abstract}
                       } = _actor} ->
      is_boolean(persistent) and
        match?(true, persistent) and
        match?(false, abstract)
    end)
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
