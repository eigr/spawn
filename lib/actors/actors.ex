defmodule Actors do
  @moduledoc """
  `Actors` It's the client API for the Spawn actors.
  Through this module we interact with the actors by creating,
  invoking or configuring them.
  """
  use Retry

  require Logger
  require OpenTelemetry.Tracer, as: Tracer

  alias Actors.Actor.Entity, as: ActorEntity
  alias Actors.Actor.Entity.Supervisor, as: ActorEntitySupervisor
  alias Actors.Actor.InvocationScheduler
  alias Actors.Actor.Pool, as: ActorPool

  alias Actors.Registry.{ActorRegistry, HostActor}

  alias Actors.Config.Vapor, as: Config

  alias Eigr.Functions.Protocol.Actors.{
    Actor,
    ActorId,
    Metadata,
    ActorSettings,
    ActorSystem,
    Registry
  }

  alias Eigr.Functions.Protocol.{
    ActorInvocationResponse,
    InvocationRequest,
    ProxyInfo,
    RegistrationRequest,
    RegistrationResponse,
    RequestStatus,
    ServiceInfo,
    SpawnRequest,
    SpawnResponse
  }

  alias Sidecar.Measurements
  alias Spawn.Utils.Nats

  import Spawn.Utils.Common, only: [to_existing_atom_or_new: 1]

  @activate_actors_min_demand 0
  @activate_actors_max_demand 4

  @erpc_timeout 5_000

  @spec get_state(ActorId.t()) :: {:ok, term()} | {:error, term()}
  def get_state(%ActorId{name: actor_name, system: system_name} = id) do
    retry with: exponential_backoff() |> randomize |> expiry(30_000),
          atoms: [:error, :exit, :noproc, :erpc, :noconnection, :timeout],
          rescue_only: [ErlangError] do
      try do
        do_lookup_action(
          system_name,
          {false, system_name, actor_name, id},
          nil,
          fn actor_ref, _actor_ref_id ->
            ActorEntity.get_state(actor_ref)
          end
        )
      rescue
        e ->
          Logger.error("Failure to make a call to actor #{inspect(actor_name)} #{inspect(e)}")

          reraise e, __STACKTRACE__
      end
    after
      result -> result
    else
      error -> error
    end
  end

  @doc """
  Registers all actors defined in HostActor.

    * `registration` - The RegistrationRequest
    * `opts` - The options to create Actors
  ##
  """
  @spec register(RegistrationRequest.t(), any()) ::
          {:ok, RegistrationResponse.t()} | {:error, RegistrationResponse.t()}
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
    actors
    |> Map.values()
    |> Enum.map(fn actor -> ActorPool.create_actor_host_pool(actor, opts) end)
    |> List.flatten()
    |> ActorRegistry.register()
    |> tap(fn _sts -> warmup_actors(actor_system, actors, opts) end)
    |> case do
      :ok ->
        status = %RequestStatus{status: :OK, message: "Accepted"}
        {:ok, %RegistrationResponse{proxy_info: get_proxy_info(), status: status}}

      _ ->
        status = %RequestStatus{status: :ERROR, message: "Failed to register one or more Actors"}

        {:error, %RegistrationResponse{proxy_info: get_proxy_info(), status: status}}
    end
  end

  defp get_proxy_info() do
    %ProxyInfo{
      protocol_major_version: 1,
      protocol_minor_version: 2,
      proxy_name: "spawn",
      proxy_version: "1.0.0-rc.17"
    }
  end

  @doc """
  Spawn actors defined in HostActor.

    * `registration` - The SpawnRequest
    * `opts` - The options to create Actors

  spawn_actor must be used when you want to create a concrete instance of an actor
  previously registered as unamed.
  That is, when an Actorid is associated with an actor of unamed type.
  This function only registers the metadata of the new actor, not activating it.
  This will occur when the sprite is first invoked.
  ##
  """
  @spec spawn_actor(SpawnRequest.t(), any()) :: {:ok, SpawnResponse.t()}
  def spawn_actor(spawn, opts \\ [])

  def spawn_actor(%SpawnRequest{actors: actors} = _spawn, _opts) do
    hosts =
      Enum.map(actors, fn %ActorId{} = id ->
        case ActorRegistry.get_hosts_by_actor(id, parent: true) do
          {:ok, actor_hosts} ->
            to_spawn_hosts(id, actor_hosts)

          error ->
            raise ArgumentError,
                  "You are trying to create an actor from an Unamed actor that has never been registered before. ActorId: #{inspect(id)}. Details. #{inspect(error)}"
        end
      end)
      |> List.flatten()

    ActorRegistry.register(hosts)

    status = %RequestStatus{status: :OK, message: "Accepted"}
    {:ok, %SpawnResponse{status: status}}
  end

  defp to_spawn_hosts(id, actor_hosts) do
    Enum.map(actor_hosts, fn %HostActor{
                               node: node,
                               actor: %Actor{} = unamed_actor,
                               opts: opts
                             } = _host ->
      spawned_actor = %Actor{unamed_actor | id: id}
      %HostActor{node: node, actor: spawned_actor, opts: opts}
    end)
  end

  @doc """
  Makes a request to an actor.

    * `request` - The InvocationRequest
    * `opts` - The options to Invoke Actors
  ##
  """
  @spec invoke(InvocationRequest.t()) :: {:ok, :async} | {:ok, term()} | {:error, term()}
  def invoke(
        %InvocationRequest{
          system: %ActorSystem{name: system_name} = _system
        } = request,
        opts \\ []
      ) do
    case Config.get(Actors, :actor_system_name) do
      name when name === system_name ->
        invoke_with_span(request, opts)

      _ ->
        invoke_with_nats(request, opts)
    end
  end

  @doc """
  Makes a request to an actor using Nats broker.

    * `request` - The InvocationRequest
    * `opts` - The options to Invoke Actors
  ##
  """
  @spec invoke(InvocationRequest.t()) :: {:ok, :async} | {:ok, term()} | {:error, term()}
  def invoke_with_nats(
        %InvocationRequest{
          actor: actor,
          system: %ActorSystem{name: system_name} = _system,
          async: async?
        } = request,
        opts \\ []
      ) do
    {_current, opts} =
      Keyword.get_and_update(opts, :span_ctx, fn span_ctx ->
        maybe_include_span(span_ctx)
      end)

    trace_context = :otel_propagator_text_map.inject_from(opts[:span_ctx], [])

    opts =
      Keyword.put(opts, :trace_context, trace_context)
      |> Keyword.merge(async: async?)

    case Nats.request(system_name, request, opts) do
      {:ok, %{body: {:error, error}}} ->
        {:error, error}

      {:ok, %{body: :async}} ->
        {:ok, :async}

      {:ok, %{body: body}} when is_binary(body) ->
        {:ok, ActorInvocationResponse.decode(body)}

      {:ok, %{body: _body}} ->
        {:error, :bad_response_type}

      {:error, :no_responders} ->
        Logger.error("Actor #{actor.id.name} not found on ActorSystem #{system_name}")
        {:error, :not_found}

      {:error, :timeout} ->
        Logger.error(
          "A timeout occurred while invoking the Actor #{actor.id.name} on ActorSystem #{system_name}"
        )

        {:error, :timeout}

      {:error, error} ->
        {:error, error}
    end
  end

  def invoke_with_span(
        %InvocationRequest{
          actor: %Actor{id: %ActorId{name: _name, system: _actor_id_system} = actor_id} = actor,
          system: %ActorSystem{} = system,
          action_name: action_name,
          async: async?,
          metadata: metadata,
          caller: caller,
          pooled: pooled?
        } = request,
        opts
      ) do
    {time, result} =
      :timer.tc(fn ->
        metadata_attributes =
          Enum.map(metadata, fn {key, value} -> {to_existing_atom_or_new(key), value} end) ++
            [{:async, async?}, {"from", get_caller(caller)}, {"target", actor_id.name}]

        {_current, opts} =
          Keyword.get_and_update(opts, :span_ctx, fn span_ctx ->
            maybe_include_span(span_ctx)
          end)

        Tracer.with_span opts[:span_ctx], "client invoke", kind: :client do
          Tracer.set_attributes(metadata_attributes)

          retry with: exponential_backoff() |> randomize |> expiry(60_000),
                atoms: [:error, :exit, :noproc, :erpc, :noconnection, :timeout],
                rescue_only: [ErlangError] do
            try do
              Tracer.add_event("lookup", [{"target", actor.id.name}])

              actor_fqdn =
                if pooled? do
                  case ActorRegistry.get_hosts_by_actor(actor_id) do
                    {:ok, actor_hosts} ->
                      host = Enum.random(actor_hosts)

                      {pooled?, system.name, host.actor.id.parent, actor_id}

                    _ ->
                      fqdn =
                        {pooled?, system.name, "#{actor.id.name}-1",
                         %ActorId{actor_id | name: "#{actor.id.name}-1", parent: actor_id.name}}

                      fqdn
                  end
                else
                  {pooled?, system.name, actor_id.name, actor_id}
                end

              do_lookup_action(system.name, actor_fqdn, system, fn actor_ref, actor_ref_id ->
                %InvocationRequest{
                  actor: %Actor{} = actor
                } = request

                request_params = %InvocationRequest{
                  request
                  | actor: %Actor{actor | id: actor_ref_id}
                }

                if is_nil(request.scheduled_to) || request.scheduled_to == 0 do
                  maybe_invoke_async(async?, actor_ref, request_params, opts)
                else
                  InvocationScheduler.schedule_invoke(request_params)

                  {:ok, :async}
                end
              end)
            rescue
              e ->
                Logger.error(
                  "Failure to make a call to actor #{inspect(actor.id.name)} #{inspect(e)}"
                )

                reraise e, __STACKTRACE__
            end
          after
            result -> result
          else
            error -> error
          end
        end
      end)

    Measurements.dispatch_invoke_duration(system.name, actor.id.name, action_name, time)
    result
  end

  defp maybe_include_span(span_ctx) do
    if is_nil(span_ctx), do: {span_ctx, OpenTelemetry.Ctx.new()}, else: {span_ctx, span_ctx}
  end

  defp get_caller(nil), do: "external"
  defp get_caller(caller), do: caller.name

  defp do_lookup_action(
         system_name,
         {pooled, system_name, parent, %ActorId{name: actor_name} = actor_id} = actor_fqdn,
         system,
         action_fun
       ) do
    Tracer.with_span "actor-lookup" do
      Tracer.set_attributes([{:actor_fqdn, actor_fqdn}])

      case Spawn.Cluster.Node.Registry.lookup(Actors.Actor.Entity, parent) do
        [{actor_ref, actor_ref_id}] ->
          Tracer.add_event("actor-status", [{"alive", true}])
          Tracer.set_attributes([{"actor-pid", "#{inspect(actor_ref)}"}])
          Logger.debug("Lookup Actor #{actor_name}. PID: #{inspect(actor_ref)}")

          # Ensures that the name change will not affect the host function call
          if pooled do
            throw("Pooled Actors are not supported yet")
            # action_fun.(actor_ref, %ActorId{actor_ref_id | name: actor_name})
          else
            action_fun.(actor_ref, actor_ref_id)
          end

        _ ->
          Tracer.add_event("actor-status", [{"alive", false}])

          Tracer.with_span "actor-reactivation" do
            Tracer.set_attributes([{:system_name, system_name}])
            Tracer.set_attributes([{:actor_name, actor_name}])

            case ActorRegistry.lookup(actor_id,
                   filter_by_parent: pooled,
                   parent: parent
                 ) do
              {:ok, %HostActor{node: node, actor: actor, opts: opts}} ->
                do_call(
                  system,
                  node,
                  actor,
                  actor_fqdn,
                  action_fun,
                  opts
                )

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

  defp do_call(
         system,
         node,
         actor,
         {pooled, _system_name, _parent, actor_name} = _actor_fqdn,
         action_fun,
         opts
       ) do
    case :erpc.call(
           node,
           __MODULE__,
           :try_reactivate_actor,
           [system, actor, opts],
           @erpc_timeout
         ) do
      {:ok, actor_ref} ->
        Tracer.set_attributes([{"actor-pid", "#{inspect(actor_ref)}"}])

        Tracer.add_event("try-reactivate-actor", [
          {"reactivation-on-node", "#{inspect(node)}"}
        ])

        if pooled,
          # Ensures that the name change will not affect the host function call
          do: action_fun.(actor_ref, %ActorId{actor.id | name: actor_name.name}),
          else: action_fun.(actor_ref, actor.id)

      _ ->
        raise ErlangError
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

  defp warmup_actors(actor_system, actors, opts) when is_map(actors) do
    spawn(fn ->
      actors
      |> Flow.from_enumerable(
        min_demand: @activate_actors_min_demand,
        max_demand: @activate_actors_max_demand
      )
      |> Flow.filter(&is_selectable?/1)
      |> Flow.map(fn {actor_name, actor} ->
        {time, result} =
          :timer.tc(&lookup_or_create_actor/4, [actor_system, actor_name, actor, opts])

        Logger.info(
          "Actor #{actor_name} Activated on Node #{inspect(Node.self())} in #{inspect(time)}ms"
        )

        result
      end)
      |> Flow.run()
    end)
  end

  @spec lookup_or_create_actor(ActorSystem.t(), String.t(), Actor.t(), any()) ::
          {:ok, pid()} | {:error, String.t()}
  defp lookup_or_create_actor(actor_system, actor_name, actor, opts) do
    case ActorEntitySupervisor.lookup_or_create_actor(actor_system, actor, opts) do
      {:ok, pid} ->
        {:ok, pid}

      _ ->
        Logger.debug("Failed to register Actor #{actor_name}")
        {:error, "Failed to register Actor #{actor_name}"}
    end
  end

  defp is_selectable?(
         {_actor_name,
          %Actor{
            metadata: %Metadata{channel_group: channel},
            settings: %ActorSettings{stateful: stateful, kind: kind}
          } = _actor}
       ) do
    cond do
      kind == :POOLED ->
        false

      match?(true, stateful) and kind != :UNAMED ->
        true

      not is_nil(channel) and byte_size(channel) > 0 ->
        true

      true ->
        false
    end
  end

  defp is_selectable?({_actor_name, %Actor{} = _actor}),
    do: false
end
