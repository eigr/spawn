defmodule ActivatorAPI.Api.Dispatcher.UnaryDispatcher do
  @moduledoc """
  `UnaryDispatcher`
  """
  @behaviour ActivatorAPI.Api.Dispatcher

  require Logger

  alias Eigr.Functions.Protocol.Actors.{
    Actor,
    ActorId,
    ActorSystem
  }

  alias Eigr.Functions.Protocol.{
    ActorInvocationResponse,
    InvocationRequest,
    Noop
  }

  import Spawn.Utils.AnySerializer

  @impl true
  def dispatch(message, stream, opts \\ []), do: handle_unary(message, stream, opts)

  defp handle_unary(message, _stream, opts) do
    actor_name = Keyword.fetch!(opts, :actor_name)
    system = Keyword.fetch!(opts, :system_name)
    action = Keyword.get(opts, :action)
    async = Keyword.get(opts, :async, false)
    pooled = Keyword.get(opts, :pooled, false)
    _timeout = Keyword.get(opts, :timeout, 30_000)
    metadata = Keyword.get(opts, :metadata, %{})
    _authentication_kind = Keyword.get(opts, :authentication_kind, "none")

    opts = []
    payload = parse_payload(message)

    req = %InvocationRequest{
      system: %ActorSystem{name: system},
      actor: %Actor{
        id: %ActorId{name: actor_name, system: system}
      },
      metadata: metadata,
      payload: payload,
      action_name: action,
      async: cast(async, :boolean),
      caller: nil,
      pooled: cast(pooled, :boolean)
    }

    case Actors.invoke_with_nats(req, opts) do
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

  defp parse_payload(message) do
    case message do
      nil -> {:noop, %Noop{}}
      %Noop{} = noop -> {:noop, noop}
      {:noop, %Noop{} = noop} -> {:noop, noop}
      {_, nil} -> {:noop, %Noop{}}
      {:value, message} -> {:value, any_pack!(message)}
      message -> {:value, any_pack!(message)}
    end
  end
end
