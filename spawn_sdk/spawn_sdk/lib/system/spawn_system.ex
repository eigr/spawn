defmodule SpawnSdk.System.SpawnSystem do
  @moduledoc """
  `SpawnSystem`
  """
  @behaviour SpawnSdk.System

  require Logger

  alias Actors
  alias Actors.Actor.Entity.EntityState

  alias Eigr.Functions.Protocol.Actors.{
    Actor,
    ActorId,
    ActorState,
    ActorSettings,
    ActorDeactivateStrategy,
    ActorSnapshotStrategy,
    ActorSystem,
    Registry,
    TimeoutStrategy
  }

  alias Eigr.Functions.Protocol.{
    ActorInvocation,
    ActorInvocationResponse,
    InvocationRequest,
    RegistrationRequest,
    RegistrationResponse,
    ServiceInfo,
    SpawnRequest,
    SpawnResponse,
    Workflow
  }

  import Spawn.Utils.AnySerializer

  @app :spawn_sdk
  @service_name "spawn-elixir"
  @service_version Application.spec(@app)[:vsn]
  @service_runtime "elixir #{System.version()}"
  @support_library_name "spawn-elixir-sdk"
  @support_library_version @service_version

  @impl SpawnSdk.System
  def register(system, actors) do
    opts = [host_interface: SpawnSdk.Interface]

    case Actors.register(build_registration_req(system, actors), opts) do
      {:ok, %RegistrationResponse{proxy_info: proxy_info, status: status}} ->
        Logger.debug(
          "Actors registration succeed. Proxy info: #{inspect(proxy_info)}. Status: #{inspect(status)}"
        )

        all_actors = merge_cache_actors(system, state_to_map(actors))

        {:ok, all_actors}

      error ->
        {:error, "Actors registration failed. Error #{inspect(error)}"}
    end
  end

  @impl SpawnSdk.System
  def spawn_actor(actor_name, spawn_actor_opts) do
    system = Keyword.get(spawn_actor_opts, :system, nil)
    actor_mod = Keyword.get(spawn_actor_opts, :actor, %{})

    if !actor_mod.__meta__(:abstract) do
      raise "Invalid Actor reference. Only abstract Actor are permited for spawning!"
    end

    new_state = state_to_map(actor_name, [actor_mod])
    opts = [host_interface: SpawnSdk.Interface]

    case Actors.spawn_actor(build_spawn_req(system, actor_name, actor_mod), opts) do
      {:ok, %SpawnResponse{status: status}} ->
        Logger.debug("Actor Spawned successfully. Status: #{inspect(status)}")

        merge_cache_actors(system, new_state)

        {:ok, new_state}

      error ->
        {:error, "Actors Spawned failing. Error #{inspect(error)}"}
    end
  end

  @impl SpawnSdk.System
  @doc "hey"
  def invoke(actor_name, invoke_opts \\ []) do
    system = Keyword.get(invoke_opts, :system, nil)
    command = Keyword.get(invoke_opts, :command, nil)
    payload = Keyword.get(invoke_opts, :payload, nil)
    async = Keyword.get(invoke_opts, :async, false)
    actor_reference = Keyword.get(invoke_opts, :ref, nil)

    if actor_reference do
      spawn_actor(actor_name, system: system, actor: actor_reference)
    end

    opts = [host_interface: SpawnSdk.Interface]

    req =
      InvocationRequest.new(
        system: %Eigr.Functions.Protocol.Actors.ActorSystem{name: system},
        actor: %Eigr.Functions.Protocol.Actors.Actor{id: %ActorId{name: actor_name}},
        value: any_pack!(payload),
        command_name: command,
        async: async
      )

    case Actors.invoke(req, opts) do
      {:ok, :async} -> {:ok, :async}
      {:ok, %ActorInvocationResponse{value: value}} -> {:ok, unpack_unknown(value)}
      error -> error
    end
  end

  def call(invocation, entity_state, default_methods) do
    %ActorInvocation{
      actor_name: name,
      actor_system: system,
      command_name: command,
      value: value
    } = invocation

    %EntityState{
      actor: %Actor{state: actor_state} = actor
    } = entity_state

    actor_state = actor_state || %{}
    current_state = Map.get(actor_state, :state)
    actor_instance = get_cached_actor(system, name)

    cond do
      Enum.member?(default_methods, command) ->
        context = Eigr.Functions.Protocol.Context.new(state: current_state)

        resp =
          ActorInvocationResponse.new(
            actor_name: name,
            actor_system: system,
            updated_context: context,
            value: current_state
          )

        {:ok, resp, entity_state}

      is_nil(actor_instance) ->
        {:error, :not_found, entity_state}

      true ->
        new_ctx = %SpawnSdk.Context{state: unpack_unknown(current_state)}

        case call_instance(actor_instance, command, value, new_ctx) do
          {:reply, %SpawnSdk.Value{state: host_state, value: response, effects: effects} = _value} ->
            resp =
              if is_nil(effects) or effects == [] do
                %ActorInvocationResponse{
                  updated_context:
                    Eigr.Functions.Protocol.Context.new(state: any_pack!(host_state)),
                  value: any_pack!(response)
                }
              else
                side_effects =
                  Enum.map(effects, fn %SpawnSdk.Flow.SideEffect{} = effect ->
                    %Eigr.Functions.Protocol.SideEffect{
                      request:
                        InvocationRequest.new(
                          system: %Eigr.Functions.Protocol.Actors.ActorSystem{name: system},
                          actor: %Eigr.Functions.Protocol.Actors.Actor{
                            id: %ActorId{name: effect.actor_name}
                          },
                          value: any_pack!(effect.payload),
                          command_name: effect.command,
                          async: true
                        )
                    }
                  end)

                %ActorInvocationResponse{
                  updated_context:
                    Eigr.Functions.Protocol.Context.new(state: any_pack!(host_state)),
                  value: any_pack!(response),
                  workflow: %Workflow{effects: side_effects}
                }
              end

            new_actor_state = %{actor_state | state: any_pack!(host_state)}

            {:ok, resp, %{entity_state | actor: %{actor | state: new_actor_state}}}

          {:error, error} ->
            {:error, error, entity_state}

          {:error, error, %SpawnSdk.Value{state: _new_state, value: _response} = _value} ->
            {:error, error, entity_state}
        end
    end
  end

  def merge_cache_actors(system, actors) do
    actors = Map.merge(get_cached_actors(system), state_to_map(actors))

    :ets.insert(:"#{system}:actors", {"actors", actors})

    actors
  end

  defp get_cached_actors(system) do
    case :ets.lookup(:"#{system}:actors", "actors") do
      [{"actors", actors}] -> actors
      _ -> %{}
    end
  end

  defp get_cached_actor(system, name) do
    get_cached_actors(system)
    |> Map.get(name)
  end

  defp call_instance(instance, command, value, context) do
    instance.handle_command({parse_command(command), unpack_unknown(value)}, context)
  rescue
    FunctionClauseError -> {:error, :command_not_handled}
    # in case atom doesn't exist
    ArgumentError -> {:error, :command_not_handled}
  end

  defp parse_command(command) when is_atom(command), do: command
  defp parse_command(command) when is_binary(command), do: String.to_existing_atom(command)

  defp build_spawn_req(system, actor_name, actor) do
    %SpawnRequest{
      actor_system:
        ActorSystem.new(
          name: system,
          registry: %Registry{actors: to_map(system, actor_name, [actor])}
        )
    }
  end

  defp build_registration_req(system, actors) do
    RegistrationRequest.new(
      service_info:
        ServiceInfo.new(
          service_name: @service_name,
          service_version: @service_version,
          service_runtime: @service_runtime,
          support_library_name: @support_library_name,
          support_library_version: @support_library_version
        ),
      actor_system:
        ActorSystem.new(
          name: system,
          registry: %Registry{actors: to_map(system, actors)}
        )
    )
  end

  defp state_to_map(actors) do
    actors
    |> Enum.into(%{}, fn
      {key, value} -> {key, value}
      actor -> {actor.__meta__(:name), actor}
    end)
  end

  defp state_to_map(actor_name, actors) do
    actors
    |> Enum.into(%{}, fn actor ->
      {actor_name, actor}
    end)
  end

  defp to_map(system, actors) do
    actors
    |> Enum.into(%{}, fn actor ->
      name = actor.__meta__(:name)
      abstract = actor.__meta__(:abstract)
      persistent = actor.__meta__(:persistent)
      snapshot_timeout = actor.__meta__(:snapshot_timeout)
      deactivate_timeout = actor.__meta__(:deactivate_timeout)

      snapshot_strategy =
        ActorSnapshotStrategy.new(
          strategy: {:timeout, TimeoutStrategy.new(timeout: snapshot_timeout)}
        )

      deactivate_strategy =
        ActorDeactivateStrategy.new(
          strategy: {:timeout, TimeoutStrategy.new(timeout: deactivate_timeout)}
        )

      {name,
       Actor.new(
         id: %ActorId{system: system, name: name},
         settings: %ActorSettings{
           abstract: abstract,
           persistent: persistent,
           snapshot_strategy: snapshot_strategy,
           deactivate_strategy: deactivate_strategy
         },
         state: ActorState.new()
       )}
    end)
  end

  defp to_map(system, actor_name, actors) do
    actors
    |> Enum.into(%{}, fn actor ->
      name = actor_name
      abstract = actor.__meta__(:abstract)
      persistent = actor.__meta__(:persistent)
      snapshot_timeout = actor.__meta__(:snapshot_timeout)
      deactivate_timeout = actor.__meta__(:deactivate_timeout)

      snapshot_strategy =
        ActorSnapshotStrategy.new(
          strategy: {:timeout, TimeoutStrategy.new(timeout: snapshot_timeout)}
        )

      deactivate_strategy =
        ActorDeactivateStrategy.new(
          strategy: {:timeout, TimeoutStrategy.new(timeout: deactivate_timeout)}
        )

      {name,
       Actor.new(
         id: %ActorId{system: system, name: name},
         settings: %ActorSettings{
           abstract: abstract,
           persistent: persistent,
           snapshot_strategy: snapshot_strategy,
           deactivate_strategy: deactivate_strategy
         },
         state: ActorState.new()
       )}
    end)
  end
end
