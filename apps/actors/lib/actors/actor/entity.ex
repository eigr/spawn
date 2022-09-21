defmodule Actors.Actor.Entity do
  use GenServer, restart: :transient
  require Logger

  alias Actors.Actor.StateManager

  alias Eigr.Functions.Protocol.Actors.{
    Actor,
    ActorDeactivateStrategy,
    ActorState,
    ActorSnapshotStrategy,
    TimeoutStrategy
  }

  alias Eigr.Functions.Protocol.{
    Context,
    ActorInvocation,
    ActorInvocationResponse,
    InvocationRequest
  }

  @default_deactivate_timeout 90_000

  @default_methods [
    "get",
    "Get",
    "get_state",
    "getState",
    "GetState"
  ]

  @default_snapshot_timeout 60_000

  @fullsweep_after 10

  @min_snapshot_threshold 500

  @timeout_factor_range 200..9000

  defmodule EntityState do
    defstruct system: nil, actor: nil, state_hash: nil

    @type t(system, actor, state_hash) :: %EntityState{
            system: system,
            actor: actor,
            state_hash: state_hash
          }

    @type t :: %EntityState{system: String.t(), actor: Actor.t(), state_hash: binary()}
  end

  @impl true
  @spec init(EntityState.t()) ::
          {:ok, EntityState.t(), {:continue, :load_state}}
  def init(
        %EntityState{
          actor: %Actor{
            name: name,
            persistent: false,
            deactivate_strategy: deactivate_strategy
          }
        } = state
      )
      when is_nil(deactivate_strategy) or deactivate_strategy == %{} do
    Process.flag(:trap_exit, true)

    Logger.notice(
      "Activating actor #{name} in Node #{inspect(Node.self())}. Persistence disabled."
    )

    strategy = {:timeout, TimeoutStrategy.new!(timeout: @default_deactivate_timeout)}
    schedule_deactivate(strategy, get_timeout_factor(@timeout_factor_range))
    {:ok, state}
  end

  def init(
        %EntityState{
          actor: %Actor{
            name: name,
            persistent: false,
            deactivate_strategy:
              %ActorDeactivateStrategy{strategy: deactivate_strategy} = _dstrategy
          }
        } = state
      ) do
    Process.flag(:trap_exit, true)

    Logger.notice(
      "Activating actor #{name} in Node #{inspect(Node.self())}. Persistence disabled."
    )

    schedule_deactivate(deactivate_strategy, get_timeout_factor(@timeout_factor_range))
    {:ok, state}
  end

  def init(
        %EntityState{
          actor: %Actor{
            name: name,
            persistent: true,
            snapshot_strategy: %ActorSnapshotStrategy{} = _snapshot_strategy,
            deactivate_strategy: deactivate_strategy
          }
        } = state
      )
      when is_nil(deactivate_strategy) or deactivate_strategy == %{} do
    Process.flag(:trap_exit, true)

    Logger.notice(
      "Activating actor #{name} in Node #{inspect(Node.self())}. Persistence enabled."
    )

    strategy = {:timeout, TimeoutStrategy.new!(timeout: @default_deactivate_timeout)}
    schedule_deactivate(strategy, get_timeout_factor(@timeout_factor_range))

    # Write soon in the first time
    schedule_snapshot_advance(@min_snapshot_threshold + get_timeout_factor(@timeout_factor_range))
    {:ok, state, {:continue, :load_state}}
  end

  def init(
        %EntityState{
          actor: %Actor{
            name: name,
            persistent: true,
            snapshot_strategy: %ActorSnapshotStrategy{} = _snapshot_strategy,
            deactivate_strategy: %ActorDeactivateStrategy{strategy: deactivate_strategy}
          }
        } = state
      ) do
    Process.flag(:trap_exit, true)

    Logger.notice(
      "Activating actor #{name} in Node #{inspect(Node.self())}. Persistence enabled."
    )

    schedule_deactivate(deactivate_strategy, get_timeout_factor(@timeout_factor_range))

    # Write soon in the first time
    schedule_snapshot_advance(@min_snapshot_threshold + get_timeout_factor(@timeout_factor_range))
    {:ok, state, {:continue, :load_state}}
  end

  @impl true
  @spec handle_continue(:load_state, EntityState.t()) :: {:noreply, EntityState.t()}
  def handle_continue(
        :load_state,
        %EntityState{
          actor: %Actor{name: name, state: actor_state} = actor
        } = state
      )
      when is_nil(actor_state) do
    Logger.debug("Initial state is empty... Getting state from state manager.")

    case StateManager.load(name) do
      {:ok, current_state} ->
        {:noreply, %EntityState{state | actor: %Actor{actor | state: current_state}}}

      {:not_found, %{}} ->
        Logger.debug("Not found initial Actor State on statestore for Actor #{name}.")
        {:noreply, state, :hibernate}
    end
  end

  def handle_continue(
        :load_state,
        %EntityState{
          actor: %Actor{name: name, state: %ActorState{} = _actor_state} = actor
        } = state
      ) do
    Logger.debug(
      "Initial state is not empty... Trying to reconcile the state with state manager."
    )

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

  @impl true
  def handle_call(
        :get_state,
        _from,
        %EntityState{
          actor: %Actor{state: actor_state} = _actor
        } = state
      )
      when is_nil(actor_state),
      do: {:reply, {:error, :not_found}, state, :hibernate}

  def handle_call(
        :get_state,
        _from,
        %EntityState{
          actor: %Actor{state: %ActorState{} = actor_state} = _actor
        } = state
      ),
      do: {:reply, {:ok, actor_state}, state, :hibernate}

  def handle_call(
        {:invocation_request,
         %InvocationRequest{
           actor: %Actor{name: name} = _actor,
           command_name: command,
           value: payload
         } = _invocation},
        _from,
        %EntityState{
          system: actor_system,
          actor: %Actor{state: actor_state}
        } = state
      ) do
    current_state = Map.get(actor_state || %{}, :state)

    ActorInvocation.new(
      actor_name: name,
      actor_system: actor_system,
      command_name: command,
      value: payload,
      current_context: Context.new(state: current_state)
    )
    |> invoke_host(state)
    |> case do
      {:ok, response, state} -> {:reply, {:ok, response}, state}
      {:error, reason, state} -> {:reply, {:error, reason}, state, :hibernate}
    end
  end

  @impl true
  def handle_cast(
        {:invocation_request,
         %InvocationRequest{
           actor: %Actor{name: name} = _actor,
           command_name: command,
           value: payload
         } = _invocation},
        %EntityState{
          system: actor_system,
          actor: %Actor{state: actor_state}
        } = state
      ) do
    current_state = Map.get(actor_state || %{}, :state)

    ActorInvocation.new(
      actor_name: name,
      actor_system: actor_system,
      command_name: command,
      value: payload,
      current_context: Context.new(state: current_state)
    )
    |> invoke_host(state)
    |> case do
      {:ok, _whatever, state} -> {:noreply, state}
      {:error, _reason, state} -> {:noreply, state, :hibernate}
    end
  end

  @impl true
  def handle_info(
        :snapshot,
        %EntityState{
          actor:
            %Actor{
              state: actor_state,
              snapshot_strategy: %ActorSnapshotStrategy{
                strategy: {:timeout, %TimeoutStrategy{timeout: _timeout}} = snapshot_strategy
              }
            } = _actor
        } = state
      )
      when is_nil(actor_state) or actor_state == %{} do
    schedule_snapshot(snapshot_strategy)
    {:noreply, state, :hibernate}
  end

  def handle_info(
        :snapshot,
        %EntityState{
          state_hash: old_hash,
          actor:
            %Actor{
              name: name,
              state: %ActorState{} = actor_state,
              snapshot_strategy: %ActorSnapshotStrategy{
                strategy: {:timeout, %TimeoutStrategy{timeout: timeout}} = snapshot_strategy
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

  def handle_info(
        :deactivate,
        %EntityState{
          actor:
            %Actor{
              name: name,
              deactivate_strategy:
                %ActorDeactivateStrategy{strategy: deactivate_strategy} =
                  _actor_deactivate_strategy
            } = _actor
        } = state
      ) do
    case Process.info(self(), :message_queue_len) do
      {:message_queue_len, 0} ->
        Logger.debug("Deactivating actor #{name} for timeout")
        {:stop, :normal, state}

      _ ->
        schedule_deactivate(deactivate_strategy)
        {:noreply, state, :hibernate}
    end
  end

  def handle_info(
        {:EXIT, pid, reason},
        %EntityState{
          actor: %Actor{name: name}
        } = state
      ) do
    Logger.warning("Received Exit message for Actor #{name} and PID #{inspect(pid)}.")

    {:stop, reason, state}
  end

  def handle_info(
        message,
        %EntityState{
          actor: %Actor{name: name, state: actor_state}
        } = state
      )
      when is_nil(actor_state) do
    Logger.warning(
      "No handled internal message for actor #{name}. Message: #{inspect(message)}. Actor state: #{inspect(state)}"
    )

    {:noreply, state, :hibernate}
  end

  def handle_info(
        message,
        %EntityState{
          actor: %Actor{name: name, state: %ActorState{} = actor_state}
        } = state
      ) do
    Logger.warning(
      "No handled internal message for actor #{name}. Message: #{inspect(message)}. Actor state: #{inspect(state)}"
    )

    StateManager.save(name, actor_state)
    {:noreply, state, :hibernate}
  end

  @impl true
  def terminate(
        reason,
        %EntityState{actor: %Actor{name: name, persistent: persistent, state: actor_state}} =
          _state
      )
      when is_nil(actor_state) or persistent == false do
    Logger.debug("Terminating actor #{name} with reason #{inspect(reason)}")
  end

  def terminate(
        reason,
        %EntityState{
          actor: %Actor{name: name, persistent: true, state: %ActorState{} = actor_state}
        } = _state
      ) do
    StateManager.save(name, actor_state)
    Logger.debug("Terminating actor #{name} with reason #{inspect(reason)}")
  end

  def start_link(%EntityState{actor: %Actor{name: name}} = state) do
    GenServer.start(__MODULE__, state,
      name: via(name),
      spawn_opt: [fullsweep_after: @fullsweep_after]
    )
  end

  @spec get_state(any) :: {:error, term()} | {:ok, term()}
  def get_state(ref) when is_pid(ref) do
    GenServer.call(ref, :get_state, 20_000)
  end

  def get_state(ref) do
    GenServer.call(via(ref), :get_state, 20_000)
  end

  @spec invoke(any, any) :: any
  def invoke(ref, request) when is_pid(ref) do
    GenServer.call(ref, {:invocation_request, request}, 30_000)
  end

  def invoke(ref, request) do
    GenServer.call(via(ref), {:invocation_request, request}, 30_000)
  end

  @spec invoke_async(any, any) :: :ok
  def invoke_async(ref, request) when is_pid(ref) do
    GenServer.cast(ref, {:invocation_request, request})
  end

  def invoke_async(ref, request) do
    GenServer.cast(via(ref), {:invocation_request, request})
  end

  defp get_timeout_factor(factor_range) when is_number(factor_range),
    do: Enum.random([factor_range])

  defp get_timeout_factor(factor_range) when is_list(factor_range), do: Enum.random(factor_range)

  defp get_timeout_factor(factor_range), do: Enum.random(factor_range)

  defp schedule_snapshot_advance(timeout),
    do:
      Process.send_after(
        self(),
        :snapshot,
        timeout
      )

  defp schedule_snapshot(snapshot_strategy, timeout_factor \\ 0),
    do:
      Process.send_after(
        self(),
        :snapshot,
        get_snapshot_interval(snapshot_strategy, timeout_factor)
      )

  defp schedule_deactivate(deactivate_strategy, timeout_factor \\ 0),
    do:
      Process.send_after(
        self(),
        :deactivate,
        get_deactivate_interval(deactivate_strategy, timeout_factor)
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

  defp get_deactivate_interval(
         {:timeout, %TimeoutStrategy{timeout: timeout}} = _timeout_strategy,
         timeout_factor \\ 0
       )
       when is_nil(timeout),
       do: @default_deactivate_timeout + timeout_factor

  defp get_deactivate_interval(
         {:timeout, %TimeoutStrategy{timeout: timeout}} = _timeout_strategy,
         timeout_factor
       ),
       do: timeout + timeout_factor

  defp update_state(
         %EntityState{
           actor: %Actor{} = _actor
         } = state,
         %Context{state: updated_state} = _user_ctx
       )
       when is_nil(updated_state),
       do: state

  defp update_state(
         %EntityState{
           actor: %Actor{state: actor_state} = _actor
         } = state,
         %Context{state: _updated_state} = _user_ctx
       )
       when is_nil(actor_state),
       do: state

  defp update_state(
         %EntityState{
           actor: %Actor{state: %ActorState{} = actor_state} = actor
         } = state,
         %Context{state: updated_state} = _user_ctx
       ) do
    new_state = %{actor_state | state: updated_state}
    %{state | actor: %{actor | state: new_state}}
  end

  defp invoke_host(
         %ActorInvocation{actor_name: name, actor_system: system, command_name: command} =
           payload,
         %EntityState{
           actor: %Actor{state: actor_state}
         } = state
       ) do
    if Enum.member?(@default_methods, command) do
      current_state = Map.get(actor_state || %{}, :state)
      context = Context.new(state: current_state)

      resp =
        ActorInvocationResponse.new(
          actor_name: name,
          actor_system: system,
          updated_context: context,
          value: current_state
        )

      {:ok, resp, state}
    else
      payload
      |> ActorInvocation.encode()
      |> Actors.Node.Client.invoke_host_actor()
      |> case do
        {:ok, %Tesla.Env{body: ""}} ->
          Logger.error("User Function Actor response Invocation body is empty")
          {:error, :no_content, state}

        {:ok, %Tesla.Env{body: nil}} ->
          Logger.error("User Function Actor response Invocation body is nil")
          {:error, :no_content, state}

        {:ok, %Tesla.Env{body: body}} ->
          with %ActorInvocationResponse{
                 updated_context: %Context{} = user_ctx
               } = resp <- ActorInvocationResponse.decode(body) do
            {:ok, resp, update_state(state, user_ctx)}
          else
            error ->
              Logger.error("Error on parse response #{inspect(error)}")
              {:error, :invalid_content, state}
          end

        {:error, reason} ->
          Logger.error("User Function Actor Invocation Unknown Error: #{inspect(reason)}")
          {:error, reason, state}
      end
    end
  end

  defp via(name) do
    {:via, Horde.Registry, {Spawn.Cluster.Node.Registry, {__MODULE__, name}}}
  end
end
