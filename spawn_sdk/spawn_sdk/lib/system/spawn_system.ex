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
    Workflow,
    Noop
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
    opts = []

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
    opts = []
    system = Keyword.get(spawn_actor_opts, :system, nil)
    parent = get_parent_actor_name(spawn_actor_opts)

    spawn_request = build_spawn_req(system, actor_name, parent)

    case Actors.spawn_actor(spawn_request, opts) do
      {:ok, %SpawnResponse{status: status}} ->
        Logger.debug("Actor Spawned successfully. Status: #{inspect(status)}")

        :ok

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
    metadata = Keyword.get(invoke_opts, :metadata, %{})
    actor_reference = Keyword.get(invoke_opts, :ref, nil)
    scheduled_to = Keyword.get(invoke_opts, :scheduled_to, nil)
    delay_in_ms = Keyword.get(invoke_opts, :delay, nil)

    if actor_reference do
      spawn_actor(actor_name, system: system, actor: actor_reference)
    end

    opts = []
    payload = parse_payload(payload)

    req =
      InvocationRequest.new(
        system: %Eigr.Functions.Protocol.Actors.ActorSystem{name: system},
        actor: %Eigr.Functions.Protocol.Actors.Actor{
          id: %ActorId{name: actor_name, system: system}
        },
        metadata: metadata,
        payload: payload,
        command_name: parse_command_name(command),
        async: async,
        caller: nil,
        scheduled_to: parse_scheduled_to(delay_in_ms, scheduled_to)
      )

    case Actors.invoke(req, opts) do
      {:ok, :async} -> {:ok, :async}
      {:ok, %ActorInvocationResponse{payload: payload}} -> {:ok, unpack_unknown(payload)}
      error -> error
    end
  end

  def call(invocation, entity_state, default_actions) do
    %ActorInvocation{
      actor: %ActorId{name: name, system: system, parent: parent},
      command_name: command,
      payload: payload,
      current_context: %Eigr.Functions.Protocol.Context{metadata: metadata},
      caller: caller
    } = invocation

    %EntityState{
      actor: %Actor{state: actor_state, id: self_actor_id, commands: commands} = actor
    } = entity_state

    actor_state = actor_state || %{}
    current_state = Map.get(actor_state, :state)
    actor_instance = get_cached_actor(system, name, parent)

    cond do
      Enum.member?(default_actions, command) and
          not Enum.any?(default_actions, fn action ->
            Enum.any?(commands, fn c -> c.name == action end)
          end) ->
        context =
          Eigr.Functions.Protocol.Context.new(
            caller: caller,
            metadata: metadata,
            self: self_actor_id,
            state: current_state
          )

        resp =
          ActorInvocationResponse.new(
            actor_name: name,
            actor_system: system,
            updated_context: context,
            payload: parse_payload(current_state)
          )

        {:ok, resp, entity_state}

      is_nil(actor_instance) ->
        {:error, :not_found, entity_state}

      true ->
        new_ctx = %SpawnSdk.Context{
          caller: caller,
          metadata: metadata,
          self: self_actor_id,
          state: unpack_unknown(current_state)
        }

        case call_instance(actor_instance, command, payload, new_ctx) do
          {:reply,
           %SpawnSdk.Value{
             state: host_state,
             value: response
           } = decoded_value} ->
            pipe = handle_pipe(decoded_value)
            forward = handle_forward(decoded_value)
            broadcast = handle_broadcast(decoded_value)
            side_effects = handle_side_effects(name, system, decoded_value)

            payload_response = parse_payload(response)

            resp = %ActorInvocationResponse{
              updated_context:
                Eigr.Functions.Protocol.Context.new(
                  caller: caller,
                  self: self_actor_id,
                  state: any_pack!(host_state)
                ),
              payload: payload_response,
              workflow: %Workflow{
                broadcast: broadcast,
                effects: side_effects,
                routing: pipe || forward
              }
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

  defp get_parent_actor_name(spawn_actor_opts) do
    case Keyword.get(spawn_actor_opts, :actor, nil) do
      nil ->
        nil

      actor when is_atom(actor) ->
        actor.__meta__(:name)

      actor when is_binary(actor) ->
        actor
    end
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
    cmd =
      cond do
        is_nil(command) -> command
        is_atom(command) -> Atom.to_string(command)
        true -> command
      end

    payload = parse_payload(payload)

    Eigr.Functions.Protocol.Broadcast.new(
      channel_group: channel,
      command_name: cmd,
      payload: payload
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

  defp handle_forward(
         %SpawnSdk.Value{
           forward: forward
         } = _value
       )
       when is_nil(forward) or forward == %{},
       do: nil

  defp handle_forward(
         %SpawnSdk.Value{
           forward: %SpawnSdk.Flow.Forward{actor_name: actor_name, command: command} = _forward
         } = _value
       ) do
    cmd = if is_atom(command), do: Atom.to_string(command), else: command

    forward =
      Eigr.Functions.Protocol.Forward.new(
        actor: actor_name,
        command_name: cmd
      )

    {:forward, forward}
  end

  defp handle_side_effects(
         _caller_name,
         _system,
         %SpawnSdk.Value{
           effects: effects
         } = _value
       )
       when is_nil(effects) or effects == [] do
    []
  end

  defp handle_side_effects(
         caller_name,
         system,
         %SpawnSdk.Value{
           effects: effects
         } = _value
       ) do
    Enum.map(effects, fn %SpawnSdk.Flow.SideEffect{} = effect ->
      payload = parse_payload(effect.payload)

      %Eigr.Functions.Protocol.SideEffect{
        request:
          InvocationRequest.new(
            system: %Eigr.Functions.Protocol.Actors.ActorSystem{name: system},
            actor: %Eigr.Functions.Protocol.Actors.Actor{
              id: %ActorId{name: effect.actor_name, system: system}
            },
            payload: payload,
            command_name: effect.command,
            async: true,
            caller: ActorId.new(name: caller_name, system: system),
            scheduled_to: effect.scheduled_to
          )
      }
    end)
  end

  defp get_cached_actor(system, name, parent) do
    ref = get_cached_actor(system, name)

    if is_nil(ref) do
      get_cached_actor(system, parent)
    else
      ref
    end
  end

  defp get_cached_actor(system, name) do
    get_cached_actors(system)
    |> Map.get(name)
  end

  defp get_cached_actors(system) do
    case :ets.lookup(:"#{system}:actors", "actors") do
      [{"actors", actors}] -> actors
      _ -> %{}
    end
  end

  defp call_instance(instance, command, %Noop{} = noop, context) do
    instance.handle_command({parse_command_name(command), noop}, context)
  end

  defp call_instance(instance, command, {:noop, %Noop{} = noop}, context) do
    instance.handle_command({parse_command_name(command), noop}, context)
  end

  defp call_instance(instance, command, {:value, value}, context) do
    instance.handle_command({parse_command_name(command), unpack_unknown(value)}, context)
  end

  defp call_instance(instance, command, nil, context) do
    instance.handle_command({parse_command_name(command), Noop.new()}, context)
  end

  defp call_instance(instance, command, value, context) do
    instance.handle_command({parse_command_name(command), unpack_unknown(value)}, context)
  end

  defp build_spawn_req(system, actor_name, parent) do
    %SpawnRequest{
      actors: [ActorId.new(name: actor_name, system: system, parent: parent)]
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
      {key, value} ->
        {key, value}

      actor ->
        {actor.__meta__(:name), actor}
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

  defp get_action(action_atom) do
    %Command{name: parse_command_name(action_atom)}
  end

  defp get_timer_action(action_atom, seconds) do
    %FixedTimerCommand{command: get_action(action_atom), seconds: seconds}
  end

  defp parse_command_name(command) when is_atom(command), do: Atom.to_string(command)
  defp parse_command_name(command) when is_binary(command), do: command

  defp parse_scheduled_to(nil, nil), do: nil

  defp parse_scheduled_to(delay_ms, _scheduled_to) when is_integer(delay_ms) do
    scheduled_to = DateTime.add(DateTime.utc_now(), delay_ms, :millisecond)
    parse_scheduled_to(nil, scheduled_to)
  end

  defp parse_scheduled_to(_delay_ms, nil), do: nil

  defp parse_scheduled_to(_delay_ms, scheduled_to) do
    DateTime.to_unix(scheduled_to, :millisecond)
  end

  defp parse_payload(response) do
    case response do
      nil -> {:noop, Noop.new()}
      %Noop{} = noop -> {:noop, noop}
      {:noop, %Noop{} = noop} -> {:noop, noop}
      {_, nil} -> {:noop, Noop.new()}
      {:value, response} -> {:value, any_pack!(response)}
      response -> {:value, any_pack!(response)}
    end
  end
end
