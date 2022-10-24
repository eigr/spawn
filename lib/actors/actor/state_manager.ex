defmodule Actors.Actor.StateManager do
  require Logger

  alias Eigr.Functions.Protocol.Actors.ActorState
  alias Google.Protobuf.Any
  alias Statestores.Schemas.Event
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

  @spec load(String.t()) :: {:ok, any}
  def load(name) do
    case StateStoreManager.load(name) do
      %Event{revision: _rev, tags: tags, data_type: type, data: data} = _event ->
        {:ok,
         ActorState.new(tags: tags, state: Google.Protobuf.Any.new(type_url: type, value: data))}

      _ ->
        {:not_found, %{}}
    end
  catch
    _kind, error ->
      {:error, error}
  end

  @spec save(String.t(), Eigr.Functions.Protocol.Actors.ActorState.t()) ::
          {:ok, Eigr.Functions.Protocol.Actors.ActorState.t()}
          | {:error, any(), Eigr.Functions.Protocol.Actors.ActorState.t()}
  def save(_name, nil), do: {:ok, nil}

  def save(_name, %ActorState{state: actor_state} = _state)
      when is_nil(actor_state) or actor_state == %{},
      do: {:ok, actor_state}

  def save(name, %ActorState{tags: tags, state: actor_state} = _state) do
    Logger.debug("Saving state for actor #{name}")

    with bytes_from_state <- Any.encode(actor_state),
         hash <- :crypto.hash(:sha256, bytes_from_state) do
      %Event{
        actor: name,
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

  @spec save_async(String.t(), Eigr.Functions.Protocol.Actors.ActorState.t()) ::
          {:ok, Eigr.Functions.Protocol.Actors.ActorState.t()}
          | {:error, any(), Eigr.Functions.Protocol.Actors.ActorState.t()}
  def save_async(name, state, timeout \\ 5000)
  def save_async(_name, nil, _timeout), do: {:ok, %{}}

  def save_async(_name, %ActorState{state: actor_state} = _state, _timeout)
      when is_nil(actor_state) or actor_state == %{},
      do: {:ok, actor_state}

  def save_async(name, %ActorState{tags: tags, state: actor_state} = _state, timeout) do
    parent = self()

    persist_data_task =
      Task.async(fn ->
        Logger.debug("Saving state for actor #{name}")

        %Event{
          actor: name,
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

  defp inserted_successfully?(ref, pid) do
    receive do
      {^ref, :ok} -> true
      {^ref, _} -> false
      {:EXIT, ^pid, _} -> false
    end
  end
end
