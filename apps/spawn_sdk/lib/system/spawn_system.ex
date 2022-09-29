defmodule SpawnSdk.System.SpawnSystem do
  @moduledoc """
  `SpawnSystem`
  """
  use GenServer
  require Logger

  @behaviour SpawnSdk.System

  alias Actors
  alias Actors.Actor.Entity.EntityState

  alias Eigr.Functions.Protocol.Actors.{
    Actor,
    ActorState,
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
    InvocationResponse,
    RegistrationRequest,
    RegistrationResponse,
    RequestStatus,
    ServiceInfo,
    SpawnRequest,
    SpawnResponse
  }

  import Spawn.Utils.AnySerializer

  @app :spawn_sdk
  @service_name "spawn-elixir"
  @service_version Application.spec(@app)[:vsn]
  @service_runtime "elixir #{System.version()}"
  @support_library_name "spawn-elixir-sdk"
  @support_library_version @service_version

  @impl true
  def init(state), do: {:ok, state, {:continue, :setup}}

  @impl true
  def handle_continue(:setup, state) do
    system = Keyword.fetch!(state, :system)
    actors = Keyword.fetch!(state, :actors)

    case do_register(system, actors) do
      {:ok, state} ->
        {:noreply, state}

      {:error, msg} ->
        {:stop, msg, state}
    end
  end

  @impl true
  def handle_call({:register, system, actors}, _from, state) do
    reply =
      {:ok, map} =
      case do_register(system, actors) do
        {:ok, map} ->
          {:ok, map}

        _ ->
          :error
      end

    if is_map(state) do
      {:reply, reply, Map.merge(state, map)}
    else
      {:reply, reply, map}
    end
  end

  def handle_call(
        {:call,
         %ActorInvocation{
           actor_name: name,
           actor_system: system,
           command_name: command,
           value: value
         } = _payload,
         %EntityState{
           actor: %Actor{state: actor_state} = actor
         } = entity_state, default_methods},
        _from,
        state
      ) do
    actor_state = actor_state || %{}
    current_state = Map.get(actor_state || %{}, :state)

    call_response =
      if Enum.member?(default_methods, command) do
        context = Eigr.Functions.Protocol.Context.new(state: current_state)

        resp =
          ActorInvocationResponse.new(
            actor_name: name,
            actor_system: system,
            updated_context: context,
            value: current_state
          )

        {:ok, resp, entity_state}
      else
        if Map.has_key?(state, name) do
          actor_instance = Map.get(state, name)

          new_ctx =
            if is_nil(current_state) or current_state == %{} do
              %SpawnSdk.Context{}
            else
              actor_state = unpack_unknown(current_state)
              %SpawnSdk.Context{state: actor_state}
            end

          case actor_instance.handle_command(
                 {String.to_existing_atom(command), unpack_unknown(value)},
                 new_ctx
               ) do
            {:ok, %SpawnSdk.Value{state: host_state, value: response} = _value} ->
              resp = %ActorInvocationResponse{
                updated_context:
                  Eigr.Functions.Protocol.Context.new(state: any_pack!(host_state)),
                value: any_pack!(response)
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

    {:reply, call_response, state}
  end

  def handle_call({:invoke, system, actor, command, payload, options}, from, state) do
    spawn(fn ->
      GenServer.reply(from, do_invoke(system, actor, command, payload, options))
    end)

    {:noreply, state}
  end

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl SpawnSdk.System
  def register(system, actors) do
    GenServer.call(__MODULE__, {:register, system, actors}, 20_000)
  end

  @impl SpawnSdk.System
  def invoke(system, actor, command, payload, options \\ []) do
    call_timeout = Keyword.get(options, :timeout, 20_000)
    GenServer.call(__MODULE__, {:invoke, system, actor, command, payload, options}, call_timeout)
  end

  def call(invocation, entity_state, default_methods) do
    GenServer.call(__MODULE__, {:call, invocation, entity_state, default_methods}, 20_000)
  end

  defp do_register(system, actors) do
    new_state = state_to_map(actors)
    opts = [host_interface: SpawnSdk.Interface]

    case Actors.register(build_registration_req(system, actors), opts) do
      {:ok, %RegistrationResponse{proxy_info: proxy_info, status: status}} ->
        Logger.debug(
          "Actors registration succeed. Proxy info: #{inspect(proxy_info)}. Status: #{inspect(status)}"
        )

        {:ok, new_state}

      error ->
        {:error, "Actors registration failed. Error #{inspect(error)}"}
    end
  end

  defp do_invoke(system, actor, command, payload, options) do
    async = Keyword.get(options, :async, false)

    req =
      InvocationRequest.new(
        system: %Eigr.Functions.Protocol.Actors.ActorSystem{name: system},
        actor: %Eigr.Functions.Protocol.Actors.Actor{name: actor, persistent: true},
        value: any_pack!(payload),
        command_name: command,
        async: async
      )

    if async do
      Actors.invoke(req)
      {:ok, "ok"}
    else
      _resp = {:ok, %ActorInvocationResponse{value: value}} = Actors.invoke(req)

      {:ok, unpack_unknown(value)}
    end
  end

  defp build_registration_req(system, actors) do
    req =
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
            registry: %Registry{actors: to_map(actors)}
          )
      )

    req
  end

  defp state_to_map(actors) do
    actors
    |> Enum.into(%{}, fn actor ->
      {actor.__meta__(:name), actor}
    end)
  end

  defp to_map(actors) do
    actors
    |> Enum.into(%{}, fn actor ->
      name = actor.__meta__(:name)
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
         name: name,
         persistent: persistent,
         snapshot_strategy: snapshot_strategy,
         deactivate_strategy: deactivate_strategy,
         state: ActorState.new()
       )}
    end)
  end
end
