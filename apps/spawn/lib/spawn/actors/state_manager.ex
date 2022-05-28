defmodule Eigr.Functions.Protocol.Actors.StateManager do
  require Logger

  alias Eigr.Functions.Protocol.Actors.ActorState
  alias Statestores.Schemas.Event
  alias Statestores.Manager.StateManager, as: StateStoreManager

  @spec load(String.t()) :: {:ok, any}
  def load(name) do
    case StateStoreManager.load(name) do
      %Event{actor: name, revision: rev, tags: tags, data_type: type, data: data} = event ->
        {:ok,
         ActorState.new(tags: tags, state: Google.Protobuf.Any.new(type_url: type, value: data))}

      _ ->
        {:not_found, %{}}
    end
  end

  @spec save(String.t(), Eigr.Functions.Protocol.Actors.ActorState.t()) ::
          {:ok, Eigr.Functions.Protocol.Actors.ActorState.t()}
          | {:error, any(), Eigr.Functions.Protocol.Actors.ActorState.t()}
  def save(_name, nil), do: {:ok, nil}

  def save(_name, %ActorState{state: actor_state} = state)
      when is_nil(actor_state) or actor_state == %{},
      do: {:ok, actor_state}

  def save(name, %ActorState{tags: tags, state: actor_state} = state) do
    Logger.debug("Saving state for actor #{name}")

    try do
      %Event{
        actor: name,
        revision: 0,
        tags: tags,
        data_type: actor_state.type_url,
        data: actor_state.value
      }
      |> StateStoreManager.save()
      |> case do
        {:ok, event} ->
          {:ok, actor_state}

        {:error, changeset} ->
          {:error, changeset, actor_state}

        other ->
          {:error, other, actor_state}
      end
    catch
      kind, error ->
        {:error, error, actor_state}
    end
  end

  @spec save_async(String.t(), Eigr.Functions.Protocol.Actors.ActorState.t()) ::
          {:ok, Eigr.Functions.Protocol.Actors.ActorState.t()}
          | {:error, any(), Eigr.Functions.Protocol.Actors.ActorState.t()}
  def save_async(_name, nil, timeout \\ 5000), do: {:ok, %{}}

  def save_async(_name, %ActorState{state: actor_state} = state, timeout)
      when is_nil(actor_state) or actor_state == %{},
      do: {:ok, actor_state}

  def save_async(name, %ActorState{tags: tags, state: actor_state} = state, timeout) do
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

      if inserted_successfully?(parent, persist_data_task.pid) do
        case res do
          {:ok, _event} ->
            {:ok, actor_state}

          {:error, changeset} ->
            {:error, changeset, actor_state}

          other ->
            {:error, other, actor_state}
        end
      else
        {:error, :unsuccessfully, actor_state}
      end
    catch
      kind, error ->
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
