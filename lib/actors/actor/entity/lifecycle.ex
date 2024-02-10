defmodule Actors.Actor.Entity.Lifecycle do
  @moduledoc """
  Handles lifecycle functions for Actor Entity
  All the public functions here assumes they are executing inside a GenServer
  """
  require Logger

  alias Actors.Actor.{Entity.EntityState, Entity.Invocation, StateManager}
  alias Actors.Actor.Pubsub
  alias Actors.Exceptions.NetworkPartitionException

  alias Eigr.Functions.Protocol.Actors.{
    Actor,
    ActorId,
    ActorDeactivationStrategy,
    ActorSettings,
    ActorSnapshotStrategy,
    Metadata,
    TimeoutStrategy
  }

  alias Sidecar.Measurements

  import Spawn.Utils.Common, only: [return_and_maybe_hibernate: 1]

  @deactivated_status "DEACTIVATED"
  @default_deactivate_timeout 10_000
  @default_snapshot_timeout 2_000
  @min_snapshot_threshold 100
  @timeout_jitter 3000

  def init(
        %EntityState{
          system: system,
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
      Application.get_env(:spawn, :split_brain_detector, Actors.Node.DefaultSplitBrainDetector)

    Logger.notice(
      "Activating Actor #{name} with Parent #{parent} in Node #{inspect(Node.self())}. Persistence #{stateful?}."
    )

    actor_name_key =
      if kind == :POOLED do
        parent
      else
        name
      end

    :ok = handle_metadata(name, system, metadata)
    :ok = Invocation.handle_timers(timer_actions, system, state.actor)

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

  def load_state(%EntityState{actor: actor, revision: revision, opts: opts} = state) do
    loaded = get_state(actor.id, revision)

    actual_state =
      case {actor.state, loaded} do
        {nil, {:ok, current_state, _, _, _}} ->
          Logger.debug(
            "Actor #{inspect(actor.id)} was created with an empty state. Trying to fetch Actor data from persistent storage."
          )

          current_state

        {state, _} when is_map(state) ->
          Logger.debug(
            "Internal state is not empty for Actor #{inspect(actor.id)}. Trying to reconcile the state with state manager."
          )

          state

        _ ->
          nil
      end

    case loaded do
      {:ok, _current_state, current_revision, status, node} ->
        split_brain_detector =
          Keyword.get(opts, :split_brain_detector, Actors.Node.DefaultSplitBrainDetector)

        case check_partition(actor.id, status, node, split_brain_detector) do
          {:continue} ->
            {:noreply, updated_state(state, actual_state, current_revision),
             {:continue, :call_init_action}}

          {:network_partition_detected, _error} ->
            handle_network_partition(actor.id)

          error ->
            handle_network_partition(actor.id, error)
        end

      {:not_found, %{}, _current_revision} ->
        Logger.debug("Not found state on statestore for Actor #{inspect(actor.id)}.")
        {:noreply, updated_state(state, actual_state, revision), {:continue, :call_init_action}}

      error ->
        handle_load_state_error(actor.name, state, error)
    end
  end

  def load_state(state), do: {:noreply, state, {:continue, :call_init_action}}

  def checkpoint(revision, %EntityState{
        actor:
          %Actor{
            id: %ActorId{name: name} = id,
            state: actor_state
          } = actor
      }) do
    response =
      if is_actor_valid?(actor) do
        Logger.debug("Doing Actor checkpoint to Actor [#{name}]")

        StateManager.save(id, actor_state, revision: revision)
      else
        {:error, :nothing}
      end

    response
  end

  def terminate(reason, %EntityState{
        revision: revision,
        actor:
          %Actor{
            id: %ActorId{name: name} = id,
            state: actor_state
          } = actor
      }) do
    if is_actor_valid?(actor) do
      StateManager.save(id, actor_state, revision: revision, status: @deactivated_status)
    end

    Logger.debug("Terminating Actor [#{name}] with reason #{inspect(reason)}")
  end

  def snapshot(
        %EntityState{
          system: system,
          state_hash: old_hash,
          revision: revision,
          actor:
            %Actor{
              id: %ActorId{name: name} = id,
              state: actor_state,
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
      if not is_nil(actor_state) and actor_state != %{} and
           StateManager.is_new?(old_hash, actor_state.state) do
        Logger.debug("Snapshotting actor #{name}")
        revision = revision + 1

        # Execute with timeout equals timeout strategy - 1 to avoid mailbox congestions
        case StateManager.save_async(id, actor_state, revision: revision, timeout: timeout - 1) do
          {:ok, _, hash} ->
            %{state | state_hash: hash, revision: revision}

          {:error, _, _, hash} ->
            %{state | state_hash: hash, revision: revision}

          {:error, :unsuccessfully, hash} ->
            %{state | state_hash: hash, revision: revision}

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

    {:noreply, state}
    |> return_and_maybe_hibernate()
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
        {:noreply, state}
    end
  end

  def deactivate(state), do: {:noreply, state, :hibernate}

  def get_state(id, revision) do
    initial = StateManager.load(id)

    if revision <= 0 do
      initial
    else
      case initial do
        {:ok, _current_state, current_revision, _status, _node} ->
          if current_revision != revision do
            Logger.warning("""
            It looks like you're looking to travel back in time. Starting state by review #{revision}.
            Previously the review was #{current_revision}. Be careful as this type of operation can cause your actor to terminate if the attributes of its previous state schema is different from the current schema.
            """)
          end

          StateManager.load(id, revision)

        initial ->
          initial
      end
    end
  end

  # Private functions

  defp updated_state(%EntityState{actor: actor} = state, actual_state, revision) do
    %EntityState{state | actor: %Actor{actor | state: actual_state}, revision: revision}
  end

  defp check_partition(id, status, node, split_brain_detector) do
    case split_brain_detector.check_network_partition(id, status, node) do
      {:ok, :continue} ->
        :continue

      {:error, :network_partition_detected} ->
        {:network_partition_detected, :network_partition_detected}

      error ->
        {:network_partition_detected, error}
    end
  end

  defp handle_network_partition(id, error \\ nil) do
    Logger.warning(
      "We have detected a possible network partition issue for Actor #{inspect(id)}. This actor will not start. Details: #{inspect(error)}"
    )

    raise NetworkPartitionException
  end

  defp handle_load_state_error(id, state, error) do
    Logger.error("Error on load state for Actor #{id}. Error: #{inspect(error)}")
    {:noreply, state, {:continue, :call_init_action}}
  end

  defp is_actor_valid?(
         %Actor{
           settings: %ActorSettings{stateful: stateful},
           state: actor_state
         } = _actor
       ) do
    stateful && !is_nil(actor_state)
  end

  defp handle_metadata(_actor, _system, metadata) when is_nil(metadata) or metadata == %{} do
    :ok
  end

  defp handle_metadata(
         actor,
         system,
         %Metadata{channel_group: channel_group, tags: _tags} = _metadata
       ) do
    :ok = subscribe(actor, system, channel_group)
    :ok
  end

  defp subscribe(_actor, _system, nil), do: :ok
  defp subscribe(_actor, _system, []), do: :ok

  defp subscribe(actor, system, channel_group) do
    Logger.debug(
      "Actor [#{actor}] from system [#{system}] is subscribing to channel_group [#{inspect(channel_group)}]"
    )

    Enum.each(channel_group, fn %{topic: topic, action: action} ->
      Pubsub.subscribe(topic, actor, system, action)
    end)
  end

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
