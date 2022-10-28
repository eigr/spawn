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
    ActorDeactivationStrategy,
    ActorSnapshotStrategy,
    ActorSystem,
    Command,
    FixedTimerCommand,
    Metadata,
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

    registration_request = build_registration_req(system, actors)

    case Actors.register(registration_request, opts) do
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

    if not actor_mod.__meta__(:abstract) do
      raise "Invalid Actor reference. Only abstract Actor are permitted for spawning!"
    end

    new_state = state_to_map(actor_name, [actor_mod])
    opts = [host_interface: SpawnSdk.Interface]

    spawn_request = build_spawn_req(system, actor_name, actor_mod)

    case Actors.spawn_actor(spawn_request, opts) do
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
        command_name: parse_command_name(command),
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
        context = Eigr.Functions.Protocol.Context.new(name: name, state: current_state)

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
          {:reply,
           %SpawnSdk.Value{
             state: host_state,
             value: response
           } = decoded_value} ->
            pipe = handle_pipe(decoded_value)
            broadcast = handle_broadcast(decoded_value)
            side_effects = handle_side_effects(system, decoded_value)

            resp = %ActorInvocationResponse{
              updated_context:
                Eigr.Functions.Protocol.Context.new(name: name, state: any_pack!(host_state)),
              value: any_pack!(response),
              workflow: %Workflow{broadcast: broadcast, effects: side_effects, routing: pipe}
            }

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

  defp handle_broadcast(
         %SpawnSdk.Value{
           broadcast: broadcast
         } = _value
       )
       when is_nil(broadcast) or broadcast == %{},
       do: nil

  defp handle_broadcast(
         %SpawnSdk.Value{
           broadcast:
             %SpawnSdk.Flow.Broadcast{channel: channel, command: command, payload: payload} =
               _broadcast
         } = _value
       ) do
    cmd = if is_atom(command), do: Atom.to_string(command), else: command

    Eigr.Functions.Protocol.Broadcast.new(
      channel_group: channel,
      command_name: cmd,
      value: any_pack!(payload)
    )
  end

  defp handle_pipe(
         %SpawnSdk.Value{
           pipe: pipe
         } = _value
       )
       when is_nil(pipe) or pipe == %{},
       do: nil

  defp handle_pipe(
         %SpawnSdk.Value{
           pipe: %SpawnSdk.Flow.Pipe{actor_name: actor_name, command: command} = _pipe
         } = _value
       ) do
    cmd = if is_atom(command), do: Atom.to_string(command), else: command

    pipe =
      Eigr.Functions.Protocol.Pipe.new(
        actor: actor_name,
        command_name: cmd
      )

    {:pipe, pipe}
  end

  defp handle_side_effects(
         _system,
         %SpawnSdk.Value{
           effects: effects
         } = _value
       )
       when is_nil(effects) or effects == [] do
    []
  end

  defp handle_side_effects(
         system,
         %SpawnSdk.Value{
           effects: effects
         } = _value
       ) do
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
    instance.handle_command({parse_command_name(command), unpack_unknown(value)}, context)
  end

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
      channel = actor.__meta__(:channel)
      abstract = actor.__meta__(:abstract)
      actions = actor.__meta__(:actions)
      persistent = actor.__meta__(:persistent)
      snapshot_timeout = actor.__meta__(:snapshot_timeout)
      deactivate_timeout = actor.__meta__(:deactivate_timeout)
      timer_actions = actor.__meta__(:timers)

      snapshot_strategy =
        ActorSnapshotStrategy.new(
          strategy: {:timeout, TimeoutStrategy.new(timeout: snapshot_timeout)}
        )

      deactivation_strategy =
        ActorDeactivationStrategy.new(
          strategy: {:timeout, TimeoutStrategy.new(timeout: deactivate_timeout)}
        )

      {name,
       Actor.new(
         id: %ActorId{system: system, name: name},
         metadata: %Metadata{channel_group: channel},
         settings: %ActorSettings{
           abstract: abstract,
           persistent: persistent,
           snapshot_strategy: snapshot_strategy,
           deactivation_strategy: deactivation_strategy
         },
         commands: Enum.map(actions, fn action -> get_action(action) end),
         timer_commands:
           Enum.map(timer_actions, fn {action, seconds} -> get_timer_action(action, seconds) end),
         state: ActorState.new()
       )}
    end)
  end

  defp to_map(system, actor_name, actors) do
    actors
    |> Enum.into(%{}, fn actor ->
      name = actor_name
      channel = actor.__meta__(:channel)
      abstract = actor.__meta__(:abstract)
      actions = actor.__meta__(:actions)
      persistent = actor.__meta__(:persistent)
      snapshot_timeout = actor.__meta__(:snapshot_timeout)
      deactivate_timeout = actor.__meta__(:deactivate_timeout)
      timer_actions = actor.__meta__(:timers)

      snapshot_strategy =
        ActorSnapshotStrategy.new(
          strategy: {:timeout, TimeoutStrategy.new(timeout: snapshot_timeout)}
        )

      deactivation_strategy =
        ActorDeactivationStrategy.new(
          strategy: {:timeout, TimeoutStrategy.new(timeout: deactivate_timeout)}
        )

      {name,
       Actor.new(
         id: %ActorId{system: system, name: name},
         metadata: %Metadata{channel_group: channel},
         settings: %ActorSettings{
           abstract: abstract,
           persistent: persistent,
           snapshot_strategy: snapshot_strategy,
           deactivation_strategy: deactivation_strategy
         },
         commands: Enum.map(actions, fn action -> get_action(action) end),
         timer_commands:
           Enum.map(timer_actions, fn {action, seconds} -> get_timer_action(action, seconds) end),
         state: ActorState.new()
       )}
    end)
  end

  defp get_action(action_atom) do
    %Command{name: parse_command_name(action_atom)}
  end

  defp get_timer_action(action_atom, seconds) do
    %FixedTimerCommand{command: get_action(action_atom), seconds: seconds}
  end

  defp parse_command_name(command) when is_atom(command), do: Atom.to_string(command)
  defp parse_command_name(command) when is_binary(command), do: command
end
