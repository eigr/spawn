defmodule Activator.Dispatcher.DefaultDispatcher do
  @behaviour Activator.Dispatcher

  require Logger

  alias Eigr.Functions.Protocol.Actors.{Actor, ActorSystem}

  alias Eigr.Functions.Protocol.{
    InvocationRequest
  }

  @impl Activator.Dispatcher
  @spec dispatch(module(), any, any, any) :: :ok | {:error, any()}
  def dispatch(encoder, data, system, actors) do
    Logger.info("Dispatching message to Actors #{inspect(actors)}")

    case encoder.decode(data) do
      {:ok, payload} ->
        Logger.debug("Decoded event: #{inspect(payload)}")

        do_dispatch(system, actors, payload)

      {:error, error} ->
        Logger.error("Failure on decode event. Error: #{inspect(error)}")
        {:error, error}
    end
  end

  defp do_dispatch(system, actors, payload) do
    actors
    |> Flow.from_enumerable(max_demand: System.schedulers_online())
    |> Flow.map(fn %{actor: actor, command: command} ->
      actor_type = Actor.new(name: actor)
      system_type = ActorSystem.new(name: system)

      Logger.debug(
        "Request for Activate Actor [#{actor}] using command [#{command}] with payload: #{inspect(payload)}"
      )

      res =
        InvocationRequest.new(
          system: system_type,
          actor: actor_type,
          value: payload,
          command_name: command,
          async: false,
          caller: nil
        )
        |> Actors.invoke()

      Logger.debug("Call result #{inspect(res)}")

      res
    end)
    |> Flow.run()
  end
end
