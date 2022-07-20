defmodule Actors.Actor.Entity do
  use GenServer, restart: :transient
  require Logger

  alias Actors.Actor.Entity.{EntityState, Finalizer, Invoker, Snapshot}
  alias Actors.Actor.StateManager

  alias Eigr.Functions.Protocol.Actors.{
    Actor,
    ActorId,
    ActorConfiguration,
    ActorDeactivateStrategy,
    ActorState,
    ActorSnapshotStrategy,
    CronCommand,
    TimerCommand,
    TimeoutStrategy
  }

  alias Eigr.Functions.Protocol.InvocationRequest

  @min_snapshot_threshold 500
  @default_deactivate_timeout 90_000
  @default_invocation_timeout 30_000
  @timeout_factor_range [200, 300, 500, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000]

  @impl true
  @spec init(EntityState.t()) ::
          {:ok, EntityState.t(), {:continue, :load_state}}
  def init(
        %EntityState{
          actor: %Actor{
            actor_id: %ActorId{name: name},
            configuration: %ActorConfiguration{
              persistent: false,
              deactivate_strategy: deactivate_strategy
            },
            crons: crons,
            timers: timers
          }
        } = state
      )
      when is_nil(deactivate_strategy) or deactivate_strategy == %{} do
    Process.flag(:trap_exit, true)

    Logger.notice(
      "Activating actor #{name} in Node #{inspect(Node.self())}. Persistence disabled."
    )

    strategy = {:timeout, TimeoutStrategy.new!(timeout: @default_deactivate_timeout)}
    Finalizer.schedule_deactivate(strategy, get_timeout_factor(@timeout_factor_range))

    handle_crons(crons)
    handle_timers(timers)
    {:ok, state}
  end

  def init(
        %EntityState{
          actor: %Actor{
            actor_id: %ActorId{name: name},
            configuration: %ActorConfiguration{
              persistent: false,
              deactivate_strategy:
                %ActorDeactivateStrategy{strategy: deactivate_strategy} = _dstrategy
            },
            crons: crons,
            timers: timers
          }
        } = state
      ) do
    Process.flag(:trap_exit, true)

    Logger.notice(
      "Activating actor #{name} in Node #{inspect(Node.self())}. Persistence disabled."
    )

    case deactivate_strategy do
      {:timeout, %TimeoutStrategy{timeout: _timeout}} ->
        Finalizer.schedule_deactivate(
          deactivate_strategy,
          get_timeout_factor(@timeout_factor_range)
        )

      _ ->
        Logger.warn("Starting Actor without Deactivate strategy set")
    end

    handle_crons(crons)
    handle_timers(timers)

    {:ok, state}
  end

  def init(
        %EntityState{
          actor: %Actor{
            actor_id: %ActorId{name: name},
            configuration: %ActorConfiguration{
              persistent: true,
              snapshot_strategy: snapshot_strategy,
              deactivate_strategy: deactivate_strategy
            },
            crons: crons,
            timers: timers
          }
        } = state
      )
      when is_nil(deactivate_strategy) or deactivate_strategy == %{} do
    Process.flag(:trap_exit, true)

    Logger.notice(
      "Activating actor #{name} in Node #{inspect(Node.self())}. Persistence enabled."
    )

    # Handle snapshot strategy first
    handle_persistence_strategy(snapshot_strategy)

    strategy = {:timeout, TimeoutStrategy.new!(timeout: @default_deactivate_timeout)}
    Finalizer.schedule_deactivate(strategy, get_timeout_factor(@timeout_factor_range))

    handle_crons(crons)
    handle_timers(timers)

    {:ok, state, {:continue, :load_state}}
  end

  def init(
        %EntityState{
          actor: %Actor{
            actor_id: %ActorId{name: name},
            configuration: %ActorConfiguration{
              persistent: true,
              snapshot_strategy: snapshot_strategy,
              deactivate_strategy: %ActorDeactivateStrategy{strategy: deactivate_strategy}
            },
            crons: crons,
            timers: timers
          }
        } = state
      ) do
    Process.flag(:trap_exit, true)

    Logger.notice(
      "Activating actor #{name} in Node #{inspect(Node.self())}. Persistence enabled."
    )

    handle_persistence_strategy(snapshot_strategy)

    case deactivate_strategy do
      {:timeout, %TimeoutStrategy{timeout: _timeout}} ->
        Finalizer.schedule_deactivate(
          deactivate_strategy,
          get_timeout_factor(@timeout_factor_range)
        )

      _ ->
        Logger.warn("Starting Actor without Deactivate strategy set")
    end

    handle_crons(crons)
    handle_timers(timers)

    {:ok, state, {:continue, :load_state}}
  end

  defp handle_crons(crons) do
    crons
    |> Flow.from_enumerable(
      min_demand: 1,
      max_demand: System.schedulers_online()
    )
    |> Flow.map(fn %CronCommand{expression: expression, command: command} = cron_command ->
      Logger.debug("Registering cron command #{inspect(cron_command)}")
      delay = get_time_from_cron(expression)
      Process.send_after(self(), {:invoke_cron, command}, delay)
    end)
    |> Flow.run()
  end

  defp handle_timers(timers) do
    timers
    |> Flow.from_enumerable(
      min_demand: 1,
      max_demand: System.schedulers_online()
    )
    |> Flow.map(fn %TimerCommand{seconds: delay, command: command} = timer_command ->
      Logger.debug("Registering timer command #{inspect(timer_command)}")
      Process.send_after(self(), {:invoke_timer, command}, delay)
    end)
    |> Flow.run()
  end

  defp get_time_from_cron(_expression) do
    10000
  end

  @impl true
  @spec handle_continue(:load_state, EntityState.t()) :: {:noreply, EntityState.t()}
  def handle_continue(
        :load_state,
        %EntityState{
          actor: %Actor{actor_id: %ActorId{name: name}, state: actor_state} = actor
        } = state
      )
      when is_nil(actor_state) do
    Logger.debug("Initial state is empty... Getting state from state manager.")

    case StateManager.load(name) do
      {:ok, current_state} ->
        {:noreply, %EntityState{state | actor: %Actor{actor | state: current_state}}}

      {:not_found, %{}} ->
        Logger.debug("Not found initial Actor State on statestore for Actor #{name}.")
        {:noreply, state}
    end
  end

  def handle_continue(
        :load_state,
        %EntityState{
          actor:
            %Actor{actor_id: %ActorId{name: name}, state: %ActorState{} = _actor_state} = actor
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
        {:noreply, state}
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
      do: {:reply, {:error, :not_found}, state}

  def handle_call(
        :get_state,
        _from,
        %EntityState{
          actor: %Actor{state: %ActorState{} = actor_state} = _actor
        } = state
      ),
      do: {:reply, {:ok, actor_state}, state}

  @impl true
  def handle_call({:invocation_request, invocation}, _from, state),
    do: Invoker.handle_invocation(invocation, state)

  @impl true
  def handle_info(:snapshot, state), do: Snapshot.handle_snapshot(state)

  def handle_info(:deactivate, state), do: Finalizer.handle_deactivate(state)

  def handle_info({:invoke_cron, _command}, state) do
    {:noreply, state}
  end

  def handle_info({:invoke_timer, _command}, state) do
    {:noreply, state}
  end

  def handle_info(
        message,
        %EntityState{
          actor: %Actor{actor_id: %ActorId{name: name}, state: actor_state}
        } = state
      )
      when is_nil(actor_state) do
    Logger.warn(
      "No handled internal message for actor #{name}. Message: #{inspect(message)}. Actor state: #{inspect(state)}"
    )

    {:noreply, state}
  end

  def handle_info(
        message,
        %EntityState{
          actor: %Actor{actor_id: %ActorId{name: name}, state: %ActorState{} = actor_state}
        } = state
      ) do
    Logger.warn(
      "No handled internal message for actor #{name}. Message: #{inspect(message)}. Actor state: #{inspect(state)}"
    )

    StateManager.save(name, actor_state)
    {:noreply, state}
  end

  @impl true
  def terminate(reason, state), do: Finalizer.handle_terminate(reason, state)

  def start_link(%EntityState{actor: %Actor{actor_id: %ActorId{name: name}}} = state) do
    GenServer.start(__MODULE__, state, name: via(name))
  end

  def get_state(name) do
    GenServer.call(via(name), :get_state, 20_000)
  end

  def invoke(
        name,
        %InvocationRequest{
          timeout: timeout
        } = request
      )
      when timeout <= 0 do
    GenServer.call(via(name), {:invocation_request, request}, @default_invocation_timeout)
  end

  def invoke(
        name,
        %InvocationRequest{
          timeout: timeout
        } = request
      ) do
    GenServer.call(via(name), {:invocation_request, request}, timeout)
  end

  def invoke_async(name, request) do
    GenServer.cast(via(name), {:invocation_request, :async, request})
  end

  defp get_timeout_factor(factor_range) when is_number(factor_range),
    do: Enum.random([factor_range])

  defp get_timeout_factor(factor_range) when is_list(factor_range), do: Enum.random(factor_range)

  defp handle_persistence_strategy(strategy) do
    case get_initial_snapshot_strategy(strategy) do
      :snapshot ->
        schedule_snapshot_advance(
          @min_snapshot_threshold + get_timeout_factor(@timeout_factor_range)
        )

        :ok

      _ ->
        Logger.debug("Persistence not based on timeouts is set: #{inspect(strategy)}")
        :ok
    end
  end

  defp get_initial_snapshot_strategy(strategy) when is_nil(strategy) or strategy == %{},
    do: :snapshot

  defp get_initial_snapshot_strategy(
         %ActorSnapshotStrategy{
           strategy: {:timeout, %TimeoutStrategy{}}
         } = _snapshot_strategy
       ) do
    :snapshot
  end

  defp schedule_snapshot_advance(timeout),
    do:
      Process.send_after(
        self(),
        :snapshot,
        timeout
      )

  defp via(name) do
    {:via, Horde.Registry, {Actors.Actor.Registry, {__MODULE__, name}}}
  end
end
