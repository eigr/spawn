defmodule ActivatorGrpc.Api.Dispatcher.UnaryDispatcher do
  @moduledoc """
  `UnaryDispatcher`
  """
  @behaviour ActivatorGrpc.Api.Dispatcher

  require Logger

  alias Eigr.Functions.Protocol.Actors.{
    Actor,
    ActorId,
    ActorSystem,
    Metadata
  }

  alias Eigr.Functions.Protocol.{
    ActorInvocationResponse,
    InvocationRequest,
    SpawnRequest,
    SpawnResponse,
    Noop
  }

  import Spawn.Utils.AnySerializer

  @impl true
  def dispatch(message, stream, opts \\ []), do: handle_unary(message, stream, opts)

  defp handle_unary(message, _stream, opts) do
    actor_name = Keyword.fetch!(opts, :actor_name)
    system = Keyword.fetch!(opts, :system_name)
    invocation_type = Keyword.get(opts, :invocation_type, "invoke")
    actor_reference = Keyword.get(opts, :parent_actor)
    action = Keyword.get(opts, :action)
    async = Keyword.get(opts, :async, false)
    pooled = Keyword.get(opts, :pooled, false)
    _timeout = Keyword.get(opts, :timeout, 30_000)
    metadata = Keyword.get(opts, :metadata, %{})
    _authentication_kind = Keyword.get(opts, :authentication_kind, "none")

    if invocation_type == "spawn-invoke" do
      spawn_actor(actor_name, system: system, actor: actor_reference)
    end

    opts = []
    payload = parse_payload(message)

    req =
      InvocationRequest.new(
        system: %ActorSystem{name: system},
        actor: %Actor{
          id: %ActorId{name: actor_name, system: system}
        },
        metadata: metadata,
        payload: payload,
        command_name: action,
        async: cast(async, :boolean),
        caller: nil,
        pooled: cast(pooled, :boolean)
      )

    case Actors.invoke(req, opts) do
      {:ok, :async} ->
        Logger.debug("Asynchronous Request ok. Send response to caller")
        :ok

      {:ok, %ActorInvocationResponse{payload: payload}} ->
        Logger.debug("Synchronous Request ok. Send response to caller")
        unpack_unknown(payload)

      error ->
        Logger.debug("Error on send Request. #{inspect(error)}")
        error
    end
  end

  defp cast(value, :boolean), do: to_boolean(value)

  defp to_boolean("false"), do: false
  defp to_boolean("true"), do: true
  defp to_boolean(value) when is_boolean(value), do: value

  defp spawn_actor(actor_name, spawn_actor_opts) do
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

  defp build_spawn_req(system, actor_name, parent) do
    %SpawnRequest{
      actors: [ActorId.new(name: actor_name, system: system, parent: parent)]
    }
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

  defp parse_payload(message) do
    case message do
      nil -> {:noop, Noop.new()}
      %Noop{} = noop -> {:noop, noop}
      {:noop, %Noop{} = noop} -> {:noop, noop}
      {_, nil} -> {:noop, Noop.new()}
      {:value, message} -> {:value, any_pack!(message)}
      message -> {:value, any_pack!(message)}
    end
  end
end
