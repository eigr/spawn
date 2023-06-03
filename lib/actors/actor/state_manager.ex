if Code.ensure_loaded?(Statestores.Supervisor) do
  defmodule Actors.Actor.StateManager do
    @moduledoc """
    `StateManager` Implements behavior that allows an Actor's state to be saved
    to persistent storage using database drivers.
    """
    require Logger

    alias Eigr.Functions.Protocol.Actors.{ActorId, ActorState}
    alias Google.Protobuf.Any
    alias Statestores.Schemas.Snapshot
    alias Statestores.Manager.StateManager, as: StateStoreManager

    def is_new?(_old_hash, new_state) when is_nil(new_state), do: false

    def is_new?(old_hash, new_state) do
      with bytes_from_state <- Any.encode(new_state),
           hash <- :crypto.hash(:sha256, bytes_from_state) do
        old_hash != hash
      else
        _ ->
          false
      end
    catch
      _kind, error ->
        {:error, error}
    end

    @spec load(ActorId.t()) :: {:ok, any}
    def load(%ActorId{} = actor_id) do
      key = generate_key(actor_id)

      case StateStoreManager.load(key) do
        %Snapshot{revision: _rev, tags: tags, data_type: type, data: data} = _event ->
          {:ok, %ActorState{tags: tags, state: %Google.Protobuf.Any{type_url: type, value: data}}}

        _ ->
          {:not_found, %{}}
      end
    catch
      _kind, error ->
        {:error, error}
    end

    @spec save(ActorId.t(), Eigr.Functions.Protocol.Actors.ActorState.t()) ::
            {:ok, Eigr.Functions.Protocol.Actors.ActorState.t()}
            | {:error, any(), Eigr.Functions.Protocol.Actors.ActorState.t()}
    def save(_actor_id, nil), do: {:ok, nil}

    def save(_actor_id, %ActorState{state: actor_state} = _state)
        when is_nil(actor_state) or actor_state == %{},
        do: {:ok, actor_state}

    def save(
          %ActorId{name: name, system: system} = actor_id,
          %ActorState{tags: tags, state: actor_state} = _state
        ) do
      Logger.debug("Saving state for actor #{name}")

      with bytes_from_state <- Any.encode(actor_state),
           hash <- :crypto.hash(:sha256, bytes_from_state),
           key <- generate_key(actor_id) do
        %Snapshot{
          id: key,
          actor: name,
          system: system,
          revision: 0,
          tags: tags,
          data_type: actor_state.type_url,
          data: actor_state.value
        }
        |> StateStoreManager.save()
        |> case do
          {:ok, _event} ->
            {:ok, actor_state, hash}

          {:error, changeset} ->
            {:error, changeset, actor_state, hash}

          other ->
            {:error, other, actor_state}
        end
      end
    catch
      _kind, error ->
        {:error, error, actor_state}
    end

    @spec save_async(ActorId.t(), Eigr.Functions.Protocol.Actors.ActorState.t()) ::
            {:ok, Eigr.Functions.Protocol.Actors.ActorState.t()}
            | {:error, any(), Eigr.Functions.Protocol.Actors.ActorState.t()}
    def save_async(actor_id, state, timeout \\ 5000)

    def save_async(_actor_id, nil, _timeout), do: {:ok, %{}}

    def save_async(_actor_id, %ActorState{state: actor_state} = _state, _timeout)
        when is_nil(actor_state) or actor_state == %{},
        do: {:ok, actor_state}

    def save_async(
          %ActorId{name: name, system: system} = actor_id,
          %ActorState{tags: tags, state: actor_state} = _state,
          timeout
        ) do
      parent = self()

      persist_data_task =
        Task.async(fn ->
          Logger.debug("Saving state for actor #{name}")
          key = generate_key(actor_id)

          %Snapshot{
            id: key,
            actor: name,
            system: system,
            revision: 0,
            tags: tags,
            data_type: actor_state.type_url,
            data: actor_state.value
          }
          |> StateStoreManager.save()
        end)

      try do
        res = Task.await(persist_data_task, timeout)

        with bytes_from_state <- Any.encode(actor_state),
             hash <- :crypto.hash(:sha256, bytes_from_state) do
          if inserted_successfully?(parent, persist_data_task.pid) do
            case res do
              {:ok, _event} ->
                {:ok, actor_state, hash}

              {:error, changeset} ->
                {:error, changeset, actor_state, hash}

              other ->
                {:error, other, actor_state}
            end
          else
            {:error, :unsuccessfully, hash}
          end
        end
      catch
        _kind, error ->
          Task.shutdown(persist_data_task, :brutal_kill)
          {:error, error, actor_state}
      end
    end

    defp generate_key(id), do: :erlang.phash2(id)

    defp inserted_successfully?(ref, pid) do
      receive do
        {^ref, :ok} -> true
        {^ref, _} -> false
        {:EXIT, ^pid, _} -> false
      end
    end
  end
else
  defmodule Actors.Actor.StateManager do
    @moduledoc false

    @not_loaded_message """
    Statestores not loaded properly
    If you are creating actors with flag `persistent: true` consider adding :spawn_statestores to your deps list
    """

    def is_new?(_old_hash, _new_state), do: raise(@not_loaded_message)
    def load(_actor_id), do: raise(@not_loaded_message)
    def save(_actor_id, _state), do: raise(@not_loaded_message)
    def save_async(_actor_id, _state, _timeout), do: raise(@not_loaded_message)
  end
end
