defmodule ActivatorGrpc.Api.Dispatcher do
  @moduledoc """
  Dispatch requests to Actors Actions.
  """
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

  def dispatch(message, stream, opts \\ []) do
    Logger.debug(
      "Received message #{inspect(message)} from stream #{inspect(stream)} with options #{inspect(opts)}."
    )

    # opts = [
    #   service_name: "io.eigr.spawn.example.TestService",
    #   original_method: "Sum",
    #   actor_name: "joe",
    #   system_name: "spawn-system",
    #   invocation_type: "invoke",
    #   request_type: "unary",
    #   input_type: Io.Eigr.Spawn.Example.MyBusinessMessage,
    #   output_type: Io.Eigr.Spawn.Example.MyBusinessMessage,
    #   pooled: "false",
    #   timeout: "30000",
    #   async: "false",
    #   stream_out_from_channel: "my-channel",
    #   authentication_kind: "basic",
    #   authentication_secret: ""
    # ]
    actor = Keyword.fetch!(opts, :actor_name)
    system = Keyword.fetch!(opts, :system_name)
    invocation_type = Keyword.get(opts, :invocation_type, :invoke)
    request_type = Keyword.get(opts, :request_type, :unary)
    pooled = Keyword.get(opts, :pooled, false)
    async = Keyword.get(opts, :async, false)
    timeout = Keyword.get(opts, :timeout, 30_000)
  end

  defp invoke_unary(actor_name, invoke_opts \\ []) do
    system = Keyword.get(invoke_opts, :system)
    command = Keyword.get(invoke_opts, :command)
    payload = Keyword.get(invoke_opts, :payload)
    async = Keyword.get(invoke_opts, :async, false)
    pooled = Keyword.get(invoke_opts, :pooled, false)
    metadata = Keyword.get(invoke_opts, :metadata, %{})
    actor_reference = Keyword.get(invoke_opts, :ref)

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
        command_name: command,
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
