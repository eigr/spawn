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
  def dispatch(message, stream, opts \\ []) do
  end

  defp handle_unary(message, stream, opts \\ []) do
    invocation_type = Keyword.get(opts, :invocation_type, "invoke")
    actor_name = Keyword.fetch!(opts, :actor_name)
    system = Keyword.fetch!(opts, :system_name)
    pooled = Keyword.get(opts, :pooled, false)
    async = Keyword.get(opts, :async, false)
    timeout = Keyword.get(opts, :timeout, 30_000)

    system = Keyword.get(opts, :system)
    action = Keyword.get(opts, :action)
    payload = Keyword.get(opts, :payload)
    async = Keyword.get(opts, :async, false)
    pooled = Keyword.get(opts, :pooled, false)
    metadata = Keyword.get(opts, :metadata, %{})
    actor_reference = Keyword.get(opts, :ref)

    if actor_reference do
      spawn_actor(actor_name, system: system, actor: actor_reference)
    end

    opts = []
    payload = parse_payload(payload)

    req =
      InvocationRequest.new(
        system: %ActorSystem{name: system},
        actor: %Actor{
          id: %ActorId{name: actor_name, system: system}
        },
        metadata: metadata,
        payload: payload,
        action_name: action,
        async: async,
        caller: nil,
        pooled: pooled
      )

    case Actors.invoke(req, opts) do
      {:ok, :async} -> {:ok, :async}
      {:ok, %ActorInvocationResponse{payload: payload}} -> {:ok, unpack_unknown(payload)}
      error -> error
    end
  end

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
