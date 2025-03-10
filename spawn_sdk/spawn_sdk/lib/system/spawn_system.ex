defmodule SpawnSdk.System.SpawnSystem do
  @moduledoc """
  `SpawnSystem`
  """
  @behaviour SpawnSdk.System

  require Logger

  alias Actors
  alias Actors.Actor.Entity.EntityState

  alias Spawn.Actors.{
    Actor,
    ActorId,
    ActorState,
    ActorSettings,
    ActorDeactivationStrategy,
    ActorSnapshotStrategy,
    ActorSystem,
    Action,
    FixedTimerAction,
    Metadata,
    Registry,
    TimeoutStrategy,
    ActorDeactivationStrategy,
    Channel,
    ProjectionSettings,
    ProjectionSubject,
    EventsRetentionStrategy
  }

  alias Spawn.{
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

  alias Google.Protobuf.Timestamp
  import Spawn.Utils.AnySerializer

  @app :spawn_sdk
  @service_name "spawn-elixir"
  @service_version Application.spec(@app)[:vsn]
  @service_runtime "elixir #{System.version()}"
  @support_library_name "spawn-elixir-sdk"
  @support_library_version @service_version

  @impl SpawnSdk.System
  def register(system, actors) do
    opts = [interface: SpawnSdk.Interface]

    registration_request = build_registration_req(system, actors)
    all_actors = merge_cache_actors(system, state_to_map(actors))

    case Actors.register(registration_request, opts) do
      {:ok, %RegistrationResponse{proxy_info: proxy_info, status: status}} ->
        Logger.debug(
          "Actors registration succeed. Proxy info: #{inspect(proxy_info)}. Status: #{inspect(status)}"
        )

        {:ok, all_actors}

      error ->
        delete_cached_actors(system, state_to_map(actors))
        {:error, "Actors registration failed. Error #{inspect(error)}"}
    end
  end

  @impl SpawnSdk.System
  def spawn_actor(actor_name, spawn_actor_opts) do
    opts = [revision: Keyword.get(spawn_actor_opts, :revision, 0)]
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
    system = Keyword.get(invoke_opts, :system)
    action = Keyword.get(invoke_opts, :action)
    payload = invoke_opts |> Keyword.get(:payload, Keyword.get(invoke_opts, :data))
    async = Keyword.get(invoke_opts, :async, false)
    pooled = Keyword.get(invoke_opts, :pooled, false)
    metadata = Keyword.get(invoke_opts, :metadata, %{})
    actor_reference = Keyword.get(invoke_opts, :ref)
    scheduled_to = Keyword.get(invoke_opts, :scheduled_to)
    delay_in_ms = Keyword.get(invoke_opts, :delay, nil)

    if is_nil(action) do
      raise "You have to specify an action"
    end

    opts = []
    payload = parse_payload(payload)

    req = %InvocationRequest{
      system: %Spawn.Actors.ActorSystem{name: system},
      actor: %Spawn.Actors.Actor{
        id: %ActorId{name: actor_name, system: system}
      },
      metadata: metadata,
      payload: payload,
      action_name: parse_action_name(action),
      async: async,
      caller: nil,
      pooled: pooled,
      scheduled_to: parse_scheduled_to(delay_in_ms, scheduled_to),
      register_ref: actor_reference
    }

    case Actors.invoke(req, opts) do
      {:ok, :async} ->
        {:ok, :async}

      {:ok, %ActorInvocationResponse{payload: payload}} ->
        try do
          {:ok, unpack_unknown(payload)}
        rescue
          Protobuf.DecodeError ->
            Logger.warning(
              "Check your actor implementation for action #{inspect(action)} to see if its setting the same type in the state output."
            )

            {:error, :invalid_state_output}

          ArgumentError ->
            Logger.warning(
              "Check your actor implementation for action #{inspect(action)}, you can only return maps on state_type: :json configured"
            )

            {:error, :invalid_state_output}
        end

      {:error, error} ->
        {:error, error}

      error ->
        {:error, error}
    end
  end

  def call(invocation, entity_state, default_actions) do
    %ActorInvocation{
      actor: %ActorId{name: name, system: system, parent: parent},
      action_name: action,
      current_context: %Spawn.Context{metadata: metadata},
      caller: caller
    } = invocation

    %EntityState{
      actor: %Actor{state: actor_state, id: self_actor_id, actions: actions} = _actor
    } = entity_state

    actor_state = actor_state || %{}
    current_state = Map.get(actor_state, :state)
    current_tags = Map.get(actor_state, :tags, %{})
    actor_instance = get_cached_actor(system, name, parent)

    if Enum.member?(default_actions, action) and
         not Enum.any?(default_actions, fn action -> contains_action?(actions, action) end) do
      context = %Spawn.Context{
        caller: caller,
        metadata: metadata,
        self: self_actor_id,
        state: current_state,
        tags: current_tags
      }

      do_call(:default_call, actor_instance, entity_state, invocation, context)
    else
      context = %SpawnSdk.Context{
        caller: caller,
        metadata: metadata,
        self: self_actor_id,
        state: unpack_unknown(current_state),
        tags: current_tags
      }

      do_call(:host_call, actor_instance, entity_state, invocation, context)
    end
  end

  def merge_cache_actors(system, actors) do
    actors = Map.merge(get_cached_actors(system), state_to_map(actors))
    :ets.insert(:"#{system}:actors", {"actors", actors})
    actors
  end

  def delete_cached_actors(system, actors) do
    :ets.delete(:"#{system}:actors", {"actors", actors})
    actors
  end

  defp contains_action?(actions, action) do
    Enum.any?(actions, fn c -> c.name == action end)
  end

  defp do_call(_call_type, actor_instance, entity_state, _invocation, _ctx)
       when is_nil(actor_instance) do
    {:error, :not_found, entity_state}
  end

  defp do_call(
         :default_call,
         _actor_instance,
         %EntityState{
           actor: %Actor{state: actor_state} = _actor
         } = entity_state,
         %ActorInvocation{
           actor: %ActorId{name: name, system: system, parent: _parent},
           action_name: _action,
           payload: _payload,
           current_context: %Spawn.Context{metadata: _metadata},
           caller: _caller
         } = _invocation,
         ctx
       ) do
    actor_state = actor_state || %{}
    current_state = Map.get(actor_state, :state)

    resp = %ActorInvocationResponse{
      actor_name: name,
      actor_system: system,
      updated_context: ctx,
      payload: parse_payload(current_state)
    }

    {:ok, resp, entity_state}
  end

  defp do_call(:host_call, actor_instance, entity_state, invocation, ctx) do
    case call_instance(actor_instance, invocation.action_name, invocation.payload, ctx) do
      {:reply, %SpawnSdk.Value{} = decoded_value} ->
        do_after_call_instance(decoded_value, entity_state, invocation, actor_instance)

      %SpawnSdk.Value{} = decoded_value ->
        do_after_call_instance(decoded_value, entity_state, invocation, actor_instance)

      {:error, error} ->
        {:error, error, entity_state}

      {:error, error, %SpawnSdk.Value{state: _new_state, value: _response} = _value} ->
        {:error, error, entity_state}
    end
  end

  defp do_after_call_instance(decoded_value, entity_state, invocation, actor_instance) do
    %SpawnSdk.Value{state: host_state, value: response, tags: tags} = decoded_value

    %EntityState{
      actor:
        %Actor{
          state: actor_state,
          id: self_actor_id,
          settings: %ActorSettings{} = actor_settings
        } = actor
    } = entity_state

    %ActorInvocation{
      actor: %ActorId{name: name, system: system, parent: _parent},
      current_context: %Spawn.Context{metadata: _metadata},
      caller: caller
    } = invocation

    current_state = Map.get(actor_state, :state)
    current_tags = Map.get(actor_state, :tags, %{})

    pipe = handle_pipe(decoded_value)
    forward = handle_forward(decoded_value)
    broadcast = handle_broadcast(decoded_value)
    side_effects = handle_side_effects(name, system, decoded_value)

    payload_response = parse_payload(response)

    state_type =
      maybe_get_state_type_from_settings(actor_settings) ||
        actor_instance.__meta__(:state_type)

    new_state =
      case pack_all_to_any(host_state || current_state, state_type) do
        {:ok, state} -> state
        {:error, :invalid_state} -> current_state
      end

    new_tags = tags || current_tags

    resp = %ActorInvocationResponse{
      updated_context: %Spawn.Context{
        caller: caller,
        self: self_actor_id,
        state: new_state,
        tags: new_tags
      },
      payload: payload_response,
      workflow: %Workflow{
        broadcast: broadcast,
        effects: side_effects,
        routing: pipe || forward
      }
    }

    new_actor_state =
      actor_state
      |> Map.put(:state, new_state)
      |> Map.put(:tags, new_tags)

    {:ok, resp, %{entity_state | actor: %{actor | state: new_actor_state}}}
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
           broadcast: %SpawnSdk.Flow.Broadcast{channel: channel, payload: payload} = _broadcast
         } = _value
       ) do
    payload = parse_payload(payload)

    %Spawn.Broadcast{
      channel_group: channel,
      payload: payload
    }
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
           pipe: %SpawnSdk.Flow.Pipe{} = pipe
         } = _value
       ) do
    cmd = if is_atom(pipe.action), do: Atom.to_string(pipe.action), else: pipe.action

    pipe = %Spawn.Pipe{
      actor: pipe.actor_name,
      action_name: cmd,
      register_ref: pipe.register_ref
    }

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
           forward: %SpawnSdk.Flow.Forward{} = forward
         } = _value
       ) do
    cmd = if is_atom(forward.action), do: Atom.to_string(forward.action), else: forward.action

    forward = %Spawn.Forward{
      actor: forward.actor_name,
      action_name: cmd,
      register_ref: forward.register_ref
    }

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

      %Spawn.SideEffect{
        request: %InvocationRequest{
          system: %Spawn.Actors.ActorSystem{name: system},
          actor: %Spawn.Actors.Actor{
            id: %ActorId{name: effect.actor_name, system: system}
          },
          payload: payload,
          action_name: effect.action,
          register_ref: effect.register_ref,
          async: true,
          caller: %ActorId{name: caller_name, system: system},
          metadata: effect.metadata,
          scheduled_to: effect.scheduled_to
        }
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

  defp call_instance(instance, action, %Noop{} = noop, context) do
    instance.handle_action({parse_action_name(action), noop}, context)
  end

  defp call_instance(instance, action, {:noop, %Noop{} = noop}, context) do
    instance.handle_action({parse_action_name(action), noop}, context)
  end

  defp call_instance(instance, action, {:value, value}, context) do
    instance.handle_action({parse_action_name(action), unpack_unknown(value)}, context)
  end

  defp call_instance(instance, action, nil, context) do
    instance.handle_action({parse_action_name(action), %Noop{}}, context)
  end

  defp call_instance(instance, action, value, context) do
    instance.handle_action({parse_action_name(action), unpack_unknown(value)}, context)
  end

  defp build_spawn_req(system, actor_name, parent) do
    %SpawnRequest{
      actors: [%ActorId{name: actor_name, system: system, parent: parent}]
    }
  end

  defp build_registration_req(system, actors) do
    %RegistrationRequest{
      service_info: %ServiceInfo{
        service_name: @service_name,
        service_version: @service_version,
        service_runtime: @service_runtime,
        support_library_name: @support_library_name,
        support_library_version: @support_library_version
      },
      actor_system: %ActorSystem{
        name: system,
        registry: %Registry{actors: to_map(system, actors)}
      }
    }
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
      kind = actor.__meta__(:kind)
      actions = actor.__meta__(:actions)
      stateful = actor.__meta__(:stateful)
      snapshot_timeout = actor.__meta__(:snapshot_timeout)
      deactivate_timeout = actor.__meta__(:deactivate_timeout)
      subjects = actor.__meta__(:subjects)
      sourceable? = actor.__meta__(:sourceable)
      events_retention = actor.__meta__(:events_retention)
      strict_ordering? = actor.__meta__(:strict_ordering)
      timer_actions = actor.__meta__(:timers)

      min_pool_size = actor.__meta__(:min_pool_size)
      max_pool_size = actor.__meta__(:max_pool_size)
      tags = actor.__meta__(:tags)

      snapshot_strategy = %ActorSnapshotStrategy{
        strategy: {:timeout, %TimeoutStrategy{timeout: snapshot_timeout}}
      }

      deactivation_strategy = %ActorDeactivationStrategy{
        strategy: {:timeout, %TimeoutStrategy{timeout: deactivate_timeout}}
      }

      channel_group =
        actor.__meta__(:channel_group)
        |> Enum.map(fn
          {topic, action} -> %Channel{topic: topic, action: action}
          topic when is_binary(topic) -> %Channel{topic: topic, action: "receive"}
        end)

      subjects =
        Enum.map(subjects, fn subject ->
          case subject do
            {actor, source_action, action} ->
              %ProjectionSubject{
                actor: actor,
                source_action: source_action,
                action: action,
                start_time: %Timestamp{seconds: 0}
              }

            {actor, source_action, action, start_time} ->
              %ProjectionSubject{
                actor: actor,
                source_action: source_action,
                action: action,
                start_time: %Timestamp{seconds: start_time}
              }
          end
        end)

      events_retention_strategy =
        case events_retention do
          :infinite ->
            %EventsRetentionStrategy{strategy: {:infinite, true}}

          value when is_number(value) ->
            %EventsRetentionStrategy{strategy: {:duration_ms, value}}
        end

      projection_settings = %ProjectionSettings{
        subjects: subjects,
        sourceable: sourceable?,
        events_retention_strategy: events_retention_strategy,
        strict_events_ordering: strict_ordering?
      }

      {name,
       %Actor{
         id: %ActorId{system: system, name: name},
         metadata: %Metadata{channel_group: channel_group},
         settings: %ActorSettings{
           kind: decode_kind(kind),
           stateful: stateful,
           min_pool_size: min_pool_size,
           max_pool_size: max_pool_size,
           snapshot_strategy: snapshot_strategy,
           deactivation_strategy: deactivation_strategy,
           projection_settings: projection_settings
         },
         actions: Enum.map(actions, fn action -> get_action(action) end),
         timer_actions:
           Enum.map(timer_actions, fn {action, seconds} -> get_timer_action(action, seconds) end),
         state: %ActorState{tags: tags}
       }}
    end)
  end

  def decode_kind(:abstract), do: :UNNAMED
  def decode_kind(:ABSTRACT), do: :UNNAMED
  def decode_kind(:unnamed), do: :UNNAMED
  def decode_kind(:UNNAMED), do: :UNNAMED
  def decode_kind(:unamed), do: :UNNAMED
  def decode_kind(:UNAMED), do: :UNNAMED
  def decode_kind(:SINGLETON), do: :NAMED
  def decode_kind(:singleton), do: :NAMED
  def decode_kind(:named), do: :NAMED
  def decode_kind(:NAMED), do: :NAMED
  def decode_kind(:TASK), do: :TASK
  def decode_kind(:task), do: :TASK
  def decode_kind(:pooled), do: :POOLED
  def decode_kind(:POOLED), do: :POOLED
  def decode_kind(:projection), do: :PROJECTION
  def decode_kind(:PROJECTION), do: :PROJECTION
  def decode_kind(_), do: :UNKNOW_KIND

  defp get_action(action_atom) do
    %Action{name: parse_action_name(action_atom)}
  end

  defp get_timer_action(action_atom, seconds) do
    %FixedTimerAction{action: get_action(action_atom), seconds: seconds}
  end

  defp parse_action_name(action) when is_atom(action), do: Atom.to_string(action)
  defp parse_action_name(action) when is_binary(action), do: action

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
      nil -> {:noop, %Noop{}}
      %Noop{} = noop -> {:noop, noop}
      {:noop, %Noop{} = noop} -> {:noop, noop}
      {_, nil} -> {:noop, %Noop{}}
      {:value, response} -> {:value, any_pack_identifying_json(response)}
      response -> {:value, any_pack_identifying_json(response)}
    end
  end

  defp any_pack_identifying_json(response) do
    cond do
      is_map(response) && not is_struct(response) ->
        json_any_pack!(response)

      is_struct(response) && is_nil(response.__struct__.transform_module()) ->
        any_pack!(response)

      true ->
        any_pack!(response)
    end
  rescue
    # when returned type is a struct but not a protobuf
    UndefinedFunctionError -> json_any_pack!(response)
  end

  defp maybe_get_state_type_from_settings(actor_settings) do
    case actor_settings do
      %ActorSettings{state_type: state_type} when state_type != "" and not is_nil(state_type) ->
        Spawn.Utils.AnySerializer.normalize_package_name(state_type)

      _ ->
        nil
    end
  end
end
