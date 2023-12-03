defmodule Spawn.Utils.Common do
  @moduledoc false
  require Logger

  alias Actors.Config.PersistentTermConfig, as: Config
  alias Eigr.Functions.Protocol.Actors.ActorId

  @spec actor_host_hash() :: integer()
  def actor_host_hash() do
    system = Config.get(:actor_system_name)
    actorhost_name = Config.get(:app_name)

    :erlang.phash2({system, actorhost_name})
  end

  @spec generate_key(String.t() | ActorId.t()) :: integer()
  def generate_key(id) when is_integer(id), do: id
  def generate_key(%{name: name, system: system}), do: :erlang.phash2({name, system})

  @spec supervisor_process_logger(module()) :: term()
  def supervisor_process_logger(module) do
    %{
      id: Module.concat([module, Logger]),
      start:
        {Task, :start,
         [
           fn ->
             Process.flag(:trap_exit, true)

             Logger.info("[SUPERVISOR] #{inspect(module)} is up")

             receive do
               {:EXIT, _pid, reason} ->
                 Logger.info(
                   "[SUPERVISOR] #{inspect(module)}:#{inspect(self())} is successfully down with reason #{inspect(reason)}"
                 )

                 :ok
             end
           end
         ]}
    }
  end

  @spec to_existing_atom_or_new(String.t()) :: atom()
  def to_existing_atom_or_new(string) do
    String.to_existing_atom(string)
  rescue
    _e ->
      String.to_atom(string)
  end

  @spec return_and_maybe_hibernate(tuple()) :: tuple()
  def return_and_maybe_hibernate(tuple) do
    queue_length = Process.info(self(), :message_queue_len)

    case queue_length do
      {:message_queue_len, 0} ->
        Tuple.append(tuple, :hibernate)

      _ ->
        tuple
    end
  end
end
