defmodule Activator.Dispatcher.DefaultDispatcher do
  @behaviour Activator.Dispatcher

  require Logger

  alias Eigr.Functions.Protocol.Actors.{Actor, ActorId, ActorSystem}

  alias Eigr.Functions.Protocol.{
    InvocationRequest
  }

  @impl Activator.Dispatcher
  @spec dispatch(any, Activator.Dispatcher.options()) :: :ok | {:error, any()}
  def dispatch(data, options) do
    encoder = Keyword.get(options, :encoder, Activator.Encoder.CloudEvent)

    case encoder.decode(data) do
      {:ok, source, id, payload} ->
        Logger.debug("Decoded event: #{inspect(payload)}")
        do_dispatch(payload, Keyword.merge(options, actor: id, command: source))

      {:error, error} ->
        Logger.error("Failure on decode event. Error: #{inspect(error)}")
        {:error, error}
    end
  end

  defp do_dispatch(payload, opts) do
    actor_name = Keyword.fetch!(opts, :actor)
    command = Keyword.fetch!(opts, :command)
    system_name = Keyword.fetch!(opts, :system)

    actor = Actor.new(id: ActorId.new(name: actor_name, system: system_name))
    system = ActorSystem.new(name: system_name)

    Logger.info("Dispaching message to Actor #{inspect(actor_name)}")

    Logger.debug(
      "Request for Activate Actor [#{actor_name}] using command [#{command}] with payload: #{inspect(payload)}"
    )

    res =
      InvocationRequest.new(
        system: system,
        actor: actor,
        payload: {:value, payload},
        command_name: command,
        async: true,
        caller: nil
      )

    Actors.invoke(res)
  end
end
