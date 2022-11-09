defmodule Actors.Actor.Entity.Lifecycle do
  @moduledoc """
  Handles lifecycle functions for Actor Entity
  All the public functions here assumes they are executing inside a GenServer
  """
  require Logger

  alias Actors.Actor.{Entity.EntityState, Entity.Invocation, StateManager}

  alias Eigr.Functions.Protocol.Actors.{
    Actor,
    ActorId,
    ActorDeactivationStrategy,
    ActorSettings,
    ActorState,
    ActorSnapshotStrategy,
    Metadata,
    TimeoutStrategy
  }

  alias Phoenix.PubSub

  @default_deactivate_timeout 10_000
  @default_snapshot_timeout 2_000
  @min_snapshot_threshold 500
  @timeout_factor_range 9000

  def init(
        %EntityState{
          actor: %Actor{
            id: %ActorId{name: name} = _id,
            metadata: metadata,
            settings:
              %ActorSettings{
                persistent: persistent?,
                snapshot_strategy: snapshot_strategy,
                deactivation_strategy: deactivation_strategy
              } = _settings,
            timer_commands: timer_commands
          }
        } = state
      ) do
    Process.flag(:trap_exit, true)

    Logger.notice(
      "Activating actor #{inspect(name)} in Node #{inspect(Node.self())}. Persistence #{persistent?}."
    )

    :ok = handle_metadata(name, metadata)
    :ok = Invocation.handle_timers(timer_commands)

    schedule_deactivate(deactivation_strategy, get_timeout_factor())
    maybe_schedule_snapshot_advance(snapshot_strategy)

    {:ok, state, {:continue, :load_state}}
  end

  def load_state(%EntityState{actor: %Actor{id: %ActorId{name: name}} = actor} = state) do
    if is_nil(actor.state) do
      "Initial state is empty. Getting state from state manager."
    else
      "Initial state is not empty. Trying to reconcile the state with state manager."
    end
    |> Logger.debug()

    case StateManager.load(name) do
      {:ok, current_state} ->
        # TODO: Merge current with old ?
        {:noreply, %EntityState{state | actor: %Actor{actor | state: current_state}}}

      {:not_found, %{}} ->
        Logger.debug("Not found initial state on statestore for Actor #{name}.")
        {:noreply, state, :hibernate}

      error ->
        Logger.error("Error on load state for Actor #{name}. Error: #{inspect(error)}")
        {:noreply, state, :hibernate}
    end
  end

  def terminate(reason, %EntityState{
        actor: %Actor{
          id: %ActorId{name: name} = _id,
          settings: %ActorSettings{persistent: persistent},
          state: actor_state
        }
      }) do
    if persistent && !is_nil(actor_state) do
      StateManager.save(name, actor_state)
    end

    Logger.debug("Terminating actor #{name} with reason #{inspect(reason)}")
  end

  def snapshot(
        %EntityState{
          actor:
            %Actor{
              state: actor_state,
              settings: %ActorSettings{
                snapshot_strategy: %ActorSnapshotStrategy{
                  strategy: {:timeout, %TimeoutStrategy{timeout: _timeout}} = snapshot_strategy
                }
              }
            } = _actor
        } = state
      )
      when is_nil(actor_state) or actor_state == %{} do
    schedule_snapshot(snapshot_strategy)
    {:noreply, state, :hibernate}
  end

  def snapshot(
        %EntityState{
          state_hash: old_hash,
          actor:
            %Actor{
              id: %ActorId{name: name} = _id,
              state: %ActorState{} = actor_state,
              settings: %ActorSettings{
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
            {:noreply, %{state | state_hash: hash}, :hibernate}

          {:error, _, _, hash} ->
            {:noreply, %{state | state_hash: hash}, :hibernate}

          {:error, :unsuccessfully, hash} ->
            {:noreply, %{state | state_hash: hash}, :hibernate}

          _ ->
            {:noreply, state, :hibernate}
        end
      else
        {:noreply, state, :hibernate}
      end

    schedule_snapshot(snapshot_strategy)
    res
  end

  def snapshot(state), do: {:noreply, state, :hibernate}

  def deactivate(
        %EntityState{
          actor:
            %Actor{
              id: %ActorId{name: name} = _id,
              settings: %ActorSettings{
                deactivation_strategy:
                  %ActorDeactivationStrategy{strategy: deactivation_strategy} =
                    _actor_deactivation_strategy
              }
            } = _actor
        } = state
      ) do
    case Process.info(self(), :message_queue_len) do
      {:message_queue_len, 0} ->
        Logger.debug("Deactivating actor #{name} for timeout")
        {:stop, :normal, state}

      _ ->
        schedule_deactivate(deactivation_strategy)
        {:noreply, state, :hibernate}
    end
  end

  def deactivate(state), do: {:noreply, state, :hibernate}

  defp handle_metadata(_actor, metadata) when is_nil(metadata) or metadata == %{} do
    :ok
  end

  defp handle_metadata(actor, %Metadata{channel_group: channel, tags: _tags} = _metadata) do
    :ok = subscribe(actor, channel)
    :ok
  end

  defp subscribe(_actor, channel) when is_nil(channel), do: :ok

  defp subscribe(actor, channel) do
    Logger.debug("Actor [#{actor}] is subscribing to channel [#{channel}]")
    PubSub.subscribe(:actor_channel, channel)
  end

  # Timeout private functions

  defp schedule_snapshot(snapshot_strategy, timeout_factor \\ 0) do
    Process.send_after(
      self(),
      :snapshot,
      get_snapshot_interval(snapshot_strategy, timeout_factor)
    )
  end

  defp maybe_schedule_snapshot_advance(%ActorSnapshotStrategy{}) do
    timeout = @min_snapshot_threshold + get_timeout_factor()

    Process.send_after(self(), :snapshot, timeout)
  end

  defp maybe_schedule_snapshot_advance(_), do: :ok

  defp schedule_deactivate(deactivation_strategy, timeout_factor \\ 0) do
    strategy = maybe_get_default_deactivation_strategy(deactivation_strategy)

    Process.send_after(
      self(),
      :deactivate,
      get_deactivate_interval(strategy, timeout_factor)
    )
  end

  defp maybe_get_default_deactivation_strategy(deactivation_strategy) do
    Map.get(
      deactivation_strategy || %{},
      :strategy,
      {:timeout, TimeoutStrategy.new!(timeout: @default_deactivate_timeout)}
    )
  end

  defp get_snapshot_interval(
         {:timeout, %TimeoutStrategy{timeout: timeout}} = _timeout_strategy,
         timeout_factor
       ),
       do: (timeout || @default_snapshot_timeout) + timeout_factor

  defp get_deactivate_interval(
         {:timeout, %TimeoutStrategy{timeout: timeout}} = _timeout_strategy,
         timeout_factor
       ),
       do: (timeout || @default_deactivate_timeout) + timeout_factor

  defp get_timeout_factor(), do:
    :rand.:rand.uniform(@timeout_factor_range)

end
