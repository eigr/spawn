defmodule SpawnSdkExample do
  @moduledoc """
  Documentation for `SpawnSdkExample`.
  """
  require Logger

  alias Io.Eigr.Spawn.Example.MyBusinessMessage
  alias SpawnSdkExample.Actors.AbstractActor

  def invoke_update_state() do
    try do
      SpawnSdk.invoke("joe",
        system: "spawn-system",
        command: "sum",
        payload: %MyBusinessMessage{value: 1}
      )
    catch
      e ->
        Logger.error("Error on invoke Actor: #{inspect(e)}")
    end
  end

  def async_invoke_update_state() do
    try do
      SpawnSdk.invoke("joe",
        system: "spawn-system",
        command: "sum",
        payload: %MyBusinessMessage{value: 1},
        async: true
      )
    catch
      e ->
        Logger.error("Error on invoke Actor: #{inspect(e)}")
    end
  end

  def invok_get_state() do
    try do
      SpawnSdk.invoke("joe", system: "spawn-system", command: "get")
    catch
      e ->
        Logger.error("Error on invoke Actor: #{inspect(e)}")
    end
  end

  def spawn_and_invoke() do
    try do
      SpawnSdk.invoke("robert_lazy",
        ref: AbstractActor,
        system: "spawn-system",
        command: "sum",
        payload: %MyBusinessMessage{value: 1}
      )
    catch
      e ->
        Logger.error("Error on invoke Actor: #{inspect(e)}")
    end
  end

  def spawn_invoke_pooled_actors() do
    try do
      SpawnSdk.invoke("pooled_actor", system: "spawn-system", command: "ping", pooled: true)
    catch
      e ->
        Logger.error("Error on invoke Actor: #{inspect(e)}")
    end
  end
end
