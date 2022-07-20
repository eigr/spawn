defmodule Actors.Actor.Entity.Snapshot do
  require Logger

  alias Actors.Actor.Entity.EntityState
  alias Actors.Actor.StateManager

  alias Eigr.Functions.Protocol.Actors.{
    Actor,
    ActorId,
    ActorConfiguration,
    ActorState,
    ActorSnapshotStrategy,
    TimeoutStrategy
  }

  @default_snapshot_timeout 60_000

  def handle_snapshot(
        %EntityState{
          actor:
            %Actor{
              state: actor_state,
              configuration: %ActorConfiguration{
                snapshot_strategy: %ActorSnapshotStrategy{
                  strategy: {:timeout, %TimeoutStrategy{timeout: _timeout}} = snapshot_strategy
                }
              }
            } = _actor
        } = state
      )
      when is_nil(actor_state) or actor_state == %{} do
    schedule_snapshot(snapshot_strategy)
    {:noreply, state}
  end

  def handle_snapshot(
        %EntityState{
          state_hash: old_hash,
          actor:
            %Actor{
              actor_id: %ActorId{name: name},
              state: %ActorState{} = actor_state,
              configuration: %ActorConfiguration{
                snapshot_strategy: %ActorSnapshotStrategy{
                  strategy: {:timeout, %TimeoutStrategy{timeout: timeout}} = snapshot_strategy
                }
              }
            } = _actor
        } = state
      ) do
    # Persist State only when necessary
    res =
      if StateManager.is_new?(old_hash, actor_state.state) do
        Logger.debug("Snapshotting actor #{name}")

        # Execute with timeout equals timeout strategy - 1 to avoid mailbox congestions
        case StateManager.save_async(name, actor_state, timeout - 1) do
          {:ok, _, hash} ->
            {:noreply, %{state | state_hash: hash}}

          {:error, _, _, hash} ->
            {:noreply, %{state | state_hash: hash}}

          {:error, :unsuccessfully, hash} ->
            {:noreply, %{state | state_hash: hash}}

          _ ->
            {:noreply, state}
        end
      else
        {:noreply, state}
      end

    schedule_snapshot(snapshot_strategy)
    res
  end

  defp schedule_snapshot(snapshot_strategy, timeout_factor \\ 0),
    do:
      Process.send_after(
        self(),
        :snapshot,
        get_snapshot_interval(snapshot_strategy, timeout_factor)
      )

  defp get_snapshot_interval(
         {:timeout, %TimeoutStrategy{timeout: timeout}} = _timeout_strategy,
         timeout_factor \\ 0
       )
       when is_nil(timeout),
       do: @default_snapshot_timeout + timeout_factor

  defp get_snapshot_interval(
         {:timeout, %TimeoutStrategy{timeout: timeout}} = _timeout_strategy,
         timeout_factor
       ),
       do: timeout + timeout_factor
end
