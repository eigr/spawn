defmodule Activator.Eventing.Dispatcher do
  @behaviour Activator.Dispatcher

  require Logger

  alias Eigr.Functions.Protocol.Actors.{Actor, ActorSystem}

  alias Eigr.Functions.Protocol.{
    InvocationRequest
  }

  alias Google.Protobuf.Any

  @impl Activator.Dispatcher
  def dispatch(data, system, actors) when is_binary(data) do
    Logger.info("Dispatching message to Actors #{inspect(actors)}")

    payload = data |> Base.decode64!() |> :erlang.iolist_to_binary() |> Any.decode()

    actors
    |> Flow.from_enumerable(max_demand: System.schedulers_online())
    |> Flow.map(fn %{actor: actor, command: command} ->
      actor_type = Actor.new(name: actor)
      system_type = ActorSystem.new(name: system)

      Logger.info(
        "Request for Activate Actor [#{actor}] using command [#{command}] with payload: #{inspect(payload)}"
      )

      res =
        InvocationRequest.new(
          system: system_type,
          actor: actor_type,
          value: payload,
          command_name: command,
          async: false
        )
        |> Actors.invoke()

      Logger.info("Call result #{inspect(res)}")

      res
    end)
    |> Flow.run()
  end

  def dispatch(%{data: payload} = _data, _system, _actors) when is_nil(payload),
    do: {:error, "Nothing to do"}

  def dispatch(%{data: payload, source: _source} = _data, system, actors) do
    Logger.info("Dispatching message to Actors #{inspect(actors)}")
    payload = Base.decode64!(payload)

    actors
    |> Flow.from_enumerable(max_demand: System.schedulers_online())
    |> Flow.map(fn %{actor: actor, command: command} ->
      actor_type = Actor.new(name: actor)
      system_type = ActorSystem.new(name: system)

      Logger.info(
        "Request for Activate Actor [#{actor}] using command [#{command}] with payload: #{inspect(payload)}"
      )

      res =
        InvocationRequest.new(
          system: system_type,
          actor: actor_type,
          value: Any.encode(payload),
          command_name: command,
          async: true
        )
        |> Actors.invoke()

      Logger.info("Call result #{inspect(res)}")

      res
    end)
    |> Flow.run()
  end
end
