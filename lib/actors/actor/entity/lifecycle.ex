defmodule Actors.Actor.Entity.Lifecycle do
  @moduledoc """
  Handles lifecycle functions for Actor Entity
  All the public functions here assumes they are executing inside a GenServer
  """
  require Logger

  alias Actors.Actor.{Entity.EntityState, Entity.Invocation, StateManager}

  alias Actors.Exceptions.NetworkPartitionException

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

  alias Sidecar.Measurements

  @deactivated_status "DEACTIVATED"
  @default_deactivate_timeout 10_000
  @default_snapshot_timeout 2_000
  @default_pubsub_group :actor_channel
  @pubsub Application.compile_env(:spawn, :pubsub_group, @default_pubsub_group)
  @min_snapshot_threshold 100
  @timeout_jitter 3000

  def init(
        %EntityState{
          actor: %Actor{
            id: %ActorId{name: name, parent: parent} = _id,
            metadata: metadata,
            settings:
              %ActorSettings{
                stateful: stateful?,
                snapshot_strategy: snapshot_strategy,
                deactivation_strategy: deactivation_strategy,
                kind: kind
              } = _settings,
            timer_actions: timer_actions
          }
        } = state
      ) do
    Process.flag(:trap_exit, true)

    split_brain_detector_mod =
      Application.get_env(
        :spawn,
        :split_brain_detector
      )

    Logger.notice(
      "Activating Actor #{name} with Parent #{parent} in Node #{inspect(Node.self())}. Persistence #{stateful?}."
    )

    actor_name_key =
      if kind == :POOLED do
        parent
      else
        name
      end

    :ok = handle_metadata(name, metadata)
    :ok = Invocation.handle_timers(timer_actions)

    :ok =
      Spawn.Cluster.Node.Registry.update_entry_value(
        Actors.Actor.Entity,
        actor_name_key,
        self(),
        state.actor.id
      )

    schedule_deactivate(deactivation_strategy, get_jitter())

    state =
      case maybe_schedule_snapshot_advance(snapshot_strategy) do
        {:ok, timer} ->
          %EntityState{
            state
            | opts:
                Keyword.merge(state.opts,
                  timer: timer,
                  split_brain_detector: split_brain_detector_mod
                )
          }

        _ ->
          %EntityState{
            state
            | opts:
                Keyword.merge(state.opts,
                  split_brain_detector: split_brain_detector_mod
                )
          }
      end

    {:ok, state, {:continue, :load_state}}
  end

  def load_state(
        %EntityState{
          actor:
            %Actor{settings: %ActorSettings{stateful: true}, id: %ActorId{name: name} = id} =
              actor,
          opts: opts
        } = state
      ) do
    if is_nil(actor.state) or (!is_nil(actor.state) and is_nil(actor.state.state)) do
      "Internal state is empty for Actor #{name}. Getting state from state manager."
    else
      # This is currently not in use by any SDK. In other words, nobody starts the Actors via SDK with some initial state.
      "Internal state is not empty for Actor #{name}. Trying to reconcile the state with state manager."
    end
    |> Logger.debug()

    case StateManager.load(id) do
      {:ok, current_state, current_revision, status, node} ->
        split_brain_detector =
          Keyword.get(opts, :split_brain_detector, Actors.Node.DefaultSplitBrainDetector)

        with {:partition_check, {:ok, :continue}} <-
               {:partition_check, split_brain_detector.check_network_partition(status, node)} do
          {:noreply,
           %EntityState{
             state
             | actor: %Actor{actor | state: current_state},
               revisions: current_revision
           }, {:continue, :call_init_action}}
        else
          {:partition_check, {:error, :network_partition_detected}} ->
            Logger.warning(
              "We have detected a possible network partition issue and therefore this actor will not start"
            )

            raise NetworkPartitionException

          error ->
            Logger.warning(
              "We have detected a possible network partition issue and therefore this actor will not start. Details: #{inspect(error)}"
            )

            raise NetworkPartitionException
        end

      {:not_found, %{}, _current_revision} ->
        Logger.debug("Not found state on statestore for Actor #{name}.")
        {:noreply, state, {:continue, :call_init_action}}

      error ->
        Logger.error("Error on load state for Actor #{name}. Error: #{inspect(error)}")
        {:noreply, state, {:continue, :call_init_action}}
    end
  end

  def load_state(state), do: {:noreply, state, {:continue, :call_init_action}}

  def terminate(reason, %EntityState{
        revisions: revisions,
        actor:
          %Actor{
            id: %ActorId{name: name} = id,
            state: actor_state
          } = actor
      }) do
    if is_actor_valid?(actor) do
      StateManager.save(id, actor_state, revision: revisions, status: @deactivated_status)
    end

    Logger.debug("Terminating actor #{name} with reason #{inspect(reason)}")
  end

  def snapshot(
        %EntityState{
          system: system,
          actor:
            %Actor{
              id: %ActorId{name: name} = _id,
              state: actor_state,
              settings: %ActorSettings{
                stateful: true,
                snapshot_strategy: %ActorSnapshotStrategy{
                  strategy: {:timeout, %TimeoutStrategy{timeout: _timeout}} = snapshot_strategy
                }
              }
            } = _actor,
          opts: opts
        } = state
      )
      when is_nil(actor_state) or actor_state == %{} do
    {:message_queue_len, size} = Process.info(self(), :message_queue_len)
    Measurements.dispatch_actor_inflights(system, name, size)

    state =
      case schedule_snapshot(snapshot_strategy, opts) do
        {:ok, timer} ->
          %EntityState{state | opts: Keyword.merge(opts, timer: timer)}

        _ ->
          state
      end

    {:noreply, state, :hibernate}
  end

  def snapshot(
        %EntityState{
          system: system,
          state_hash: old_hash,
          revisions: revisions,
          actor:
            %Actor{
              id: %ActorId{name: name} = id,
              state: %ActorState{} = actor_state,
              settings: %ActorSettings{
                stateful: true,
                snapshot_strategy: %ActorSnapshotStrategy{
                  strategy: {:timeout, %TimeoutStrategy{timeout: timeout}} = snapshot_strategy
                }
              }
            } = _actor,
          opts: opts
        } = state
      ) do
    {:message_queue_len, size} = Process.info(self(), :message_queue_len)
    Measurements.dispatch_actor_inflights(system, name, size)

    # Persist State only when necessary
    new_state =
      if StateManager.is_new?(old_hash, actor_state.state) do
        Logger.debug("Snapshotting actor #{name}")
        revision = revisions + 1

        # Execute with timeout equals timeout strategy - 1 to avoid mailbox congestions
        case StateManager.save_async(id, actor_state, revision: revision, timeout: timeout - 1) do
          {:ok, _, hash} ->
            %{state | state_hash: hash, revisions: revision}

          {:error, _, _, hash} ->
            %{state | state_hash: hash, revisions: revision}

          {:error, :unsuccessfully, hash} ->
            %{state | state_hash: hash, revisions: revision}

          _ ->
            state
        end
      else
        state
      end

    state =
      case schedule_snapshot(snapshot_strategy, opts) do
        {:ok, timer} ->
          %EntityState{new_state | opts: Keyword.merge(opts, timer: timer)}

        _ ->
          new_state
      end

    {:noreply, state, :hibernate}
  end

  def snapshot(state), do: {:noreply, state, :hibernate}

  def deactivate(
        %EntityState{
          system: system,
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
    queue_length = Process.info(self(), :message_queue_len)
    {:message_queue_len, size} = queue_length
    Measurements.dispatch_actor_inflights(system, name, size)

    case queue_length do
      {:message_queue_len, 0} ->
        Logger.debug("Deactivating actor #{name} for timeout")
        {:stop, :shutdown, state}

      _ ->
        schedule_deactivate(deactivation_strategy)
        {:noreply, state, :hibernate}
    end
  end

  def deactivate(state), do: {:noreply, state, :hibernate}

  defp is_actor_valid?(
         %Actor{
           settings: %ActorSettings{stateful: stateful},
           state: actor_state
         } = _actor
       ) do
    stateful && !is_nil(actor_state)
  end

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
    PubSub.subscribe(@pubsub, channel)
  end

  # Timeout private functions

  defp schedule_snapshot(snapshot_strategy, opts) do
    timeout_factor = Keyword.get(opts, :timeout_factor, 0)
    timer = Keyword.get(opts, :timer, nil)

    if !is_nil(timer) do
      Process.cancel_timer(timer)
    end

    {:ok,
     Process.send_after(
       self(),
       :snapshot,
       get_snapshot_interval(snapshot_strategy, timeout_factor)
     )}
  end

  defp maybe_schedule_snapshot_advance(%ActorSnapshotStrategy{}) do
    timeout = @min_snapshot_threshold + get_jitter()

    {:ok, Process.send_after(self(), :snapshot, timeout)}
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

  defp maybe_get_default_deactivation_strategy({type, strategy}), do: {type, strategy}

  defp maybe_get_default_deactivation_strategy(deactivation_strategy) do
    Map.get(
      deactivation_strategy || %{},
      :strategy,
      {:timeout, %TimeoutStrategy{timeout: @default_deactivate_timeout}}
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

  defp get_jitter(), do: :rand.uniform(@timeout_jitter)
end
