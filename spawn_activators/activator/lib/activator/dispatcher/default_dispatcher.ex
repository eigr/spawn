defmodule Activator.Dispatcher.DefaultDispatcher do
  @behaviour Activator.Dispatcher

  require Logger

  alias Spawn.Actors.{Actor, ActorId, ActorSystem}

  alias Spawn.{
    InvocationRequest,
    Noop
  }

  @impl Activator.Dispatcher
  @spec dispatch(any, Activator.Dispatcher.options()) :: :ok | {:error, any()}
  def dispatch(data, options) when is_nil(data) do
    do_dispatch(nil, options)
  end

  def dispatch(data, options) do
    encoder = Keyword.get(options, :encoder, Activator.Encoder.CloudEvent)

    case encoder.decode(data) do
      {:ok, source, id, payload} ->
        Logger.debug("Decoded event: #{inspect(payload)}")
        do_dispatch(payload, Keyword.merge(options, actor: id, action: source))

      {:error, error} ->
        Logger.error("Failure on decode event. Error: #{inspect(error)}")
        {:error, error}
    end
  end

  defp do_dispatch(payload, opts) when is_nil(payload) do
    async? = Keyword.get(opts, :async, true)
    actor_name = Keyword.fetch!(opts, :actor)
    action = Keyword.fetch!(opts, :action)
    system_name = Keyword.fetch!(opts, :system)

    actor = %Actor{id: %ActorId{name: actor_name, system: system_name}}
    system = %ActorSystem{name: system_name}

    Logger.info("Dispaching message to Actor #{inspect(actor_name)}")

    Logger.debug(
      "Request for Activate Actor [#{actor_name}] using action [#{action}] without payload"
    )

    req = %InvocationRequest{
      system: system,
      actor: actor,
      payload: {:noop, %Noop{}},
      action_name: action,
      async: async?,
      caller: nil
    }

    Actors.invoke_with_nats(req, opts)
  end

  defp do_dispatch(payload, opts) do
    async? = Keyword.get(opts, :async, true)
    actor_name = Keyword.fetch!(opts, :actor)
    action = Keyword.fetch!(opts, :action)
    system_name = Keyword.fetch!(opts, :system)

    actor = %Actor{id: %ActorId{name: actor_name, system: system_name}}
    system = %ActorSystem{name: system_name}

    Logger.info("Dispaching message to Actor #{inspect(actor_name)}")

    Logger.debug(
      "Request for Activate Actor [#{actor_name}] using action [#{action}] with payload: #{inspect(payload)}"
    )

    req = %InvocationRequest{
      system: system,
      actor: actor,
      payload: {:value, payload},
      action_name: action,
      async: async?,
      caller: nil
    }

    Actors.invoke_with_nats(req, opts)
  end
end
