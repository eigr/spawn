defmodule Proxy.Activators.Eventing.Dispatcher do
  @behaviour Activators.Dispatcher

  alias Eigr.Functions.Protocol.Actors.{Actor, ActorSystem}

  alias Eigr.Functions.Protocol.{
    InvocationRequest
  }

  @impl Activators.Dispatcher
  def dispatch(%{data: payload} = _data) when is_nil(payload), do: {:error, "Nothing to do"}

  def dispatch(%{data: payload, source: source} = _data) do
    options = parse_source(source)
    cmd = Map.get(options, :command)
    system = ActorSystem.new(name: Map.get(options, :system_name))
    actor = Actor.new(name: Map.get(options, :actor_name))

    InvocationRequest.new(
      system: system,
      actor: actor,
      value: payload,
      command_name: cmd,
      async: true
    )
    |> Actors.invoke()
  end

  defp parse_source(source) when is_binary(source) do
    parts = String.split(source, "/")
    %{system_name: Enum.at(parts, 2), actor_name: Enum.at(parts, 4), command: Enum.at(parts, 5)}
  end
end
