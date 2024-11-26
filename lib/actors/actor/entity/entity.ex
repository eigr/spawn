defmodule Actors.Actor.Entity do
  @moduledoc """
  Manages the lifecycle of the Host Actor through the `Entity` module.

  The `Entity` module provides a GenServer-based implementation for controlling the
  lifecycle of actors, handling various actions, and interacting with the underlying
  actor system.

  ## Behavior

  The module implements GenServer behavior with transient restart semantics.

  - **Initialization:** The module initializes the actor state and handles the loading of persisted states.

  - **State Handling:** Manages the lifecycle of the actor, including state transitions, initialization actions, and periodic snapshots.

  - **Interaction:** Exposes client APIs for retrieving actor state, synchronously invoking actions, and asynchronously triggering actions.

  - **Terminating:** Ensures that the actor's state will be saved and performs all necessary cleanups.

  ## Client APIs

  The following client APIs are available for interaction:

  - `start_link/1`: Starts the entity for a given actor state.
  - `get_state/2`: Retrieves the actor state directly from memory.
  - `invoke/3`: Synchronously invokes an action on an actor.
  - `invoke_async/3`: Asynchronously invokes an action on an actor.

  ### Callbacks

  - `init/1`: Initializes the actor entity.
  - `handle_continue/2`: Handles asynchronous events during the actor lifecycle.
  - `handle_call/3`: Handles synchronous calls to the actor.
  - `handle_cast/2`: Handles asynchronous casts to the actor.
  - `handle_info/2`: Handles informational messages.
  - `terminate/2`: Terminates the actor entity.

  ## Client APIs

  start_link/1: Starts the entity for a given actor state.

  get_state/2: Retrieves the actor state directly from memory.

  invoke/3: Synchronously invokes an action on an actor.

  invoke_async/3: Asynchronously invokes an action on an actor.

  ## Usage

  To use this module, start the actor by calling `start_link/1` with an initial actor state.
  Interaction with the actor is facilitated through the provided client APIs such as `get_state/2`, `invoke/3`, and `invoke_async/3`.

  ## Example

  ```elixir
  {:ok, actor} = Actors.Actor.Entity.start_link(%EntityState{actor: %Actor{id: %ActorId{name: "example"}}})
  state = Actors.Actor.Entity.get_state(actor)
  {:ok, result} = Actors.Actor.Entity.invoke(actor, %InvocationRequest{action: :some_action})
  ```

  Note: Ensure proper configuration and integration with the distributed system for seamless actor interactions.

  """
  use GenServer, restart: :transient
  require Logger

  alias Actors.Actor.StateManager
  alias Actors.Actor.Entity.EntityState
  alias Actors.Actor.Entity.Lifecycle
  alias Actors.Actor.Entity.Invocation

  alias Eigr.Functions.Protocol.Actors.Actor
  alias Eigr.Functions.Protocol.Actors.ActorId
  alias Eigr.Functions.Protocol.Actors.ActorState
  alias Eigr.Functions.Protocol.Actors.Healthcheck.HealthCheckReply
  alias Eigr.Functions.Protocol.Actors.Healthcheck.Status, as: HealthcheckStatus

  alias Eigr.Functions.Protocol.ActorInvocationResponse

  alias Eigr.Functions.Protocol.State.Checkpoint
  alias Eigr.Functions.Protocol.State.Revision

  alias Spawn.Cluster.Provisioner.Scheduler, as: FlameScheduler
  alias Spawn.Cluster.Provisioner.SpawnTask

  import Spawn.Utils.Common, only: [return_and_maybe_hibernate: 1]

  @default_call_timeout :infinity
  @fullsweep_after 10

  @impl true
  @spec init(EntityState.t()) ::
          {:ok, EntityState.t(), {:continue, :load_state}}
  def init(initial_state) do
    if function_exported?(:proc_lib, :set_label, 1) do
      apply(:proc_lib, :set_label, ["Spawn.Actor.Entity"])
    end

    initial_state
    |> EntityState.unpack()
    |> Lifecycle.init()
    |> parse_packed_response()
  end

  @impl true
  @spec handle_continue(atom(), EntityState.t()) :: {:noreply, EntityState.t()}
  def handle_continue(action, state) do
    state = EntityState.unpack(state)

    case action do
      :load_state ->
        Lifecycle.load_state(state)

      :call_init_action ->
        Invocation.invoke_init(state)

      action ->
        do_handle_continue(action, state)
    end
    |> parse_packed_response()
  end

  defp do_handle_continue(action, state) do
    Logger.warning("Unhandled handle_continue for action #{action}")

    {:noreply, state}
    |> return_and_maybe_hibernate()
  end

  @doc """
  Handles different types of incoming `call` actions for an actor process.

  This function is responsible for processing actions sent to the actor. It distinguishes between invocation requests
  and other default actions. The main action handled is the `:invocation_request`, which includes logic for task-based
  actors and synchronous execution.

  ### Parameters:
    - `action`: Represents the action to be handled by the actor. It can be a tuple of `{:invocation_request, invocation, opts}`
      or other actions.
    - `from`: The caller process that made the request, usually a tuple containing the PID and a reference.
    - `state`: The current state of the actor, typically passed in a packed format and unpacked at the start of the function.

  ### Action Handling:
    - `{:invocation_request, invocation, opts}`:
      - If the actor is of kind `:TASK`, the function schedules the task execution remotely using `FlameScheduler.schedule_and_invoke/2`.
      - For non-task actors, the function directly invokes the action using `Invocation.invoke/2`.
    - Default actions are delegated to `do_handle_defaults/3`.

  ### Return Value:
  The function returns a packed response, which is either the result of an invocation or the default action handling.
  The response is further processed by `parse_packed_response/1`.

  ### Workflow:
  1. The actor's state is unpacked via `EntityState.unpack/1`.
  2. Based on the `action`:
      - For `{:invocation_request, invocation, opts}`, the function checks if the actor is of kind `:TASK`:
        - If true, the invocation is handled remotely with the remote task scheduler (`FlameScheduler`), ensuring proper remote invocation while maintaining local state consistency.
        - Otherwise, the action is invoked locally.
      - For other actions, `do_handle_defaults/3` is called to manage additional behaviors.
  3. The final response is returned as a packed structure after being processed by `parse_packed_response/1`.

  ### See Also:
    - `handle_invocation_request/4`
    - `schedule_task_invocation/3`
    - `FlameScheduler.schedule_and_invoke/2`
    - `Invocation.invoke/2`
  """
  @impl true
  def handle_call(action, from, state) do
    state = EntityState.unpack(state)

    case action do
      {:invocation_request, invocation, opts} ->
        handle_invocation_request(invocation, opts, from, state)

      _ ->
        do_handle_defaults(action, from, state)
    end
    |> parse_packed_response()
  end

  defp handle_invocation_request(invocation, opts, from, state) do
    opts = Keyword.merge(opts, from_pid: from)

    case state.actor.settings.kind do
      :TASK ->
        schedule_task_invocation(invocation, opts, state)

      _ ->
        Invocation.invoke({invocation, opts}, state)
        |> then(fn
          {:ok, source_request, dest_response, updated_state, source_opts} ->
            Invocation.handle_response(source_request, dest_response, updated_state, source_opts)

          res ->
            res
        end)
    end
  end

  defp schedule_task_invocation(invocation, opts, state) do
    task_opts = Keyword.merge(opts, timeout: :infinity)
    request_type = Keyword.get(opts, :async, false)

    %SpawnTask{
      actor_name: state.actor.id.name,
      invocation: invocation,
      opts: task_opts,
      state: state,
      async: request_type
    }
    |> FlameScheduler.schedule_and_invoke(&Invocation.invoke/2)
    |> then(fn
      {:ok, source_request, dest_response, updated_state, source_opts} ->
        # Handle response here ensures that the full response behavior will be given by the Actor
        # that initiated the remote call and not the target POD,
        # which could cause unwanted side effects.
        # For this works we need to disable track_resources: false
        Invocation.handle_response(source_request, dest_response, updated_state, source_opts)

      res ->
        res
    end)
    |> handle_scheduler_response()
  end

  defp handle_scheduler_response(
         {:reply, {:ok, %ActorInvocationResponse{} = resp}, %EntityState{} = _state} =
           payload
       ) do
    Logger.debug("Remoting Scheduler response for invocation: #{inspect(resp)}")
    payload
  end

  defp handle_scheduler_response(
         {:reply, {:ok, %ActorInvocationResponse{} = resp}, %EntityState{} = _state, _signal} =
           payload
       ) do
    Logger.debug("Remoting Scheduler response for invocation: #{inspect(resp)}")
    payload
  end

  defp handle_scheduler_response(
         {:noreply, %EntityState{} = _state} =
           payload
       ) do
    Logger.debug("Remoting Scheduler response for invocation ok")
    payload
  end

  defp handle_scheduler_response(
         {:noreply, %EntityState{} = _state, _signal} =
           payload
       ) do
    Logger.debug("Remoting Scheduler response for invocation ok")
    payload
  end

  defp handle_scheduler_response(another) do
    Logger.error("Error during Remoting Scheduler invocation. Details: #{inspect(another)}")
    another
  end

  defp do_handle_defaults(action, from, state) do
    case action do
      :get_state ->
        do_handle_get_state(action, from, state)

      :readiness ->
        do_handle_readiness(action, from, state)

      :liveness ->
        do_handle_liveness(action, from, state)

      :checkpoint ->
        do_handle_checkpoint(action, from, state)

      {:restore, checkpoint} ->
        do_handle_restore(checkpoint, from, state)
    end
  end

  defp do_handle_readiness(
         _action,
         _from,
         %EntityState{
           actor: %Actor{} = _actor
         } = state
       ) do
    {:reply,
     {:ok,
      %HealthCheckReply{
        status: %HealthcheckStatus{
          status: "OK",
          details: "I'm alive!",
          updated_at: %Google.Protobuf.Timestamp{
            seconds: DateTime.to_unix(DateTime.utc_now(:second))
          }
        }
      }}, state}
    |> return_and_maybe_hibernate()
  end

  defp do_handle_liveness(
         _action,
         _from,
         %EntityState{
           actor: %Actor{} = _actor
         } = state
       ) do
    {:reply,
     {:ok,
      %HealthCheckReply{
        status: %HealthcheckStatus{
          status: "OK",
          details: "I'm still alive!",
          updated_at: %Google.Protobuf.Timestamp{
            seconds: DateTime.to_unix(DateTime.utc_now(:second))
          }
        }
      }}, state}
    |> return_and_maybe_hibernate()
  end

  defp do_handle_checkpoint(
         _action,
         _from,
         %EntityState{
           revision: revision,
           actor: %Actor{state: actor_state} = _actor
         } = state
       )
       when is_nil(actor_state) do
    {:reply, {:ok, %Checkpoint{revision: %Revision{value: revision}}}, state}
    |> return_and_maybe_hibernate()
  end

  defp do_handle_checkpoint(
         _action,
         _from,
         %EntityState{
           revision: revision,
           actor: %Actor{} = _actor
         } = state
       ) do
    revision = revision + 1

    case Lifecycle.checkpoint(revision, state) do
      {:ok, actor_state, _hash} ->
        checkpoint = %Checkpoint{revision: %Revision{value: revision}, state: actor_state}

        {:reply, {:ok, checkpoint}, state}
        |> return_and_maybe_hibernate()

      _ ->
        {:reply, :error, state}
        |> return_and_maybe_hibernate()
    end
  end

  defp do_handle_restore(
         %Checkpoint{revision: %Revision{value: revision}},
         _from,
         %EntityState{
           actor: %Actor{id: %ActorId{} = id} = _actor
         } = state
       ) do
    case Lifecycle.get_state(id, revision) do
      {:ok, current_state, current_revision, _status, _node} ->
        checkpoint = %Checkpoint{
          revision: %Revision{value: current_revision},
          state: current_state
        }

        {:reply, {:ok, checkpoint}, current_state}
        |> return_and_maybe_hibernate()

      _ ->
        {:reply, :error, state}
        |> return_and_maybe_hibernate()
    end

    {:reply, {:ok, :not_found}, state}
  end

  defp do_handle_get_state(
         :get_state,
         _from,
         %EntityState{
           actor: %Actor{state: actor_state} = _actor
         } = state
       )
       when is_nil(actor_state) do
    {:reply, {:error, :not_found}, state}
    |> return_and_maybe_hibernate()
  end

  defp do_handle_get_state(
         :get_state,
         _from,
         %EntityState{
           actor: %Actor{state: %ActorState{} = actor_state} = _actor
         } = state
       ) do
    {:reply, {:ok, actor_state}, state}
    |> return_and_maybe_hibernate()
  end

  @impl true
  def handle_cast(action, state) do
    state = EntityState.unpack(state)

    case action do
      {:invocation_request, invocation, opts} ->
        opts = Keyword.merge(opts, async: true)

        handle_invocation_request(invocation, opts, nil, state)
        |> reply_to_noreply()

      action ->
        do_handle_cast(action, state)
    end
    |> parse_packed_response()
  end

  defp do_handle_cast(action, state) do
    Logger.warning("Unhandled handle_cast for action #{action}")

    {:noreply, state}
    |> return_and_maybe_hibernate()
  end

  @impl true
  def handle_info(action, state) do
    state = EntityState.unpack(state)

    case action do
      :snapshot ->
        Lifecycle.snapshot(state)

      :deactivate ->
        Lifecycle.deactivate(state)

      action ->
        do_handle_info(action, state)
    end
    |> parse_packed_response()
  end

  defp do_handle_info(
         {:EXIT, from, {:name_conflict, {key, value}, registry, pid}},
         %EntityState{
           actor: %Actor{id: %ActorId{} = id}
         } = state
       ) do
    Logger.warning(
      "A conflict has been detected for ActorId #{inspect(id)}. Possible Actor Rebalance or NetSplit!
      Trace Data: [
        self: #{inspect(self())},
        from: #{inspect(from)},
        key: #{inspect(key)},
        value: #{inspect(value)},
        registry: #{inspect(registry)},
        pid: #{inspect(pid)}
      ] "
    )

    {:stop, :conflict, state}
  end

  defp do_handle_info(
         {:EXIT, from, reason},
         %EntityState{
           actor: %Actor{id: %ActorId{name: name} = _id}
         } = state
       ) do
    Logger.warning(
      "Received Exit message for Actor #{name} and PID #{inspect(from)}. Reason: #{inspect(reason)}"
    )

    {:stop, reason, state}
  end

  defp do_handle_info(
         message,
         %EntityState{
           revision: revision,
           actor: %Actor{id: %ActorId{name: name} = id, state: actor_state}
         } = state
       ) do
    Logger.warning(
      "No handled internal message for actor #{name}. Message: #{inspect(message)}. Actor state: #{inspect(state)}"
    )

    # what is the correct status here? For now we will use UNKNOWN
    if not is_nil(actor_state),
      do: StateManager.save(id, actor_state, revision: revision, status: "UNKNOWN")

    {:noreply, state}
    |> return_and_maybe_hibernate()
  end

  @impl true
  def terminate(action, state) do
    state = EntityState.unpack(state)

    Lifecycle.terminate(action, state)
  end

  ## Client APIs

  @doc """
  Starts the entity for a given actor state.
  """
  def start_link(%EntityState{actor: %Actor{id: %ActorId{name: name} = _id}} = state) do
    GenServer.start_link(__MODULE__, state,
      name: via(name),
      spawn_opt: [fullsweep_after: @fullsweep_after]
    )
  end

  @doc """
  Retrieve the Actor state direct from memory.
  """
  @spec get_state(any, any) :: {:error, term()} | {:ok, term()}
  def get_state(ref, opts \\ [])

  def get_state(ref, opts) when is_pid(ref) do
    timeout = Keyword.get(opts, :timeout, @default_call_timeout)
    GenServer.call(ref, :get_state, timeout)
  end

  def get_state(ref, opts) do
    timeout = Keyword.get(opts, :timeout, @default_call_timeout)
    GenServer.call(via(ref), :get_state, timeout)
  end

  @doc """
  Retrieve the health check readiness status.
  """
  @spec readiness(any, any) :: {:error, term()} | {:ok, term()}
  def readiness(ref, opts \\ [])

  def readiness(ref, opts) when is_pid(ref) do
    timeout = Keyword.get(opts, :timeout, @default_call_timeout)
    GenServer.call(ref, :readiness, timeout)
  end

  def readiness(ref, opts) do
    timeout = Keyword.get(opts, :timeout, @default_call_timeout)
    GenServer.call(via(ref), :readiness, timeout)
  end

  @doc """
  Retrieve the health check liveness status.
  """
  @spec readiness(any, any) :: {:error, term()} | {:ok, term()}
  def liveness(ref, opts \\ [])

  def liveness(ref, opts) when is_pid(ref) do
    timeout = Keyword.get(opts, :timeout, @default_call_timeout)
    GenServer.call(ref, :liveness, timeout)
  end

  def liveness(ref, opts) do
    timeout = Keyword.get(opts, :timeout, @default_call_timeout)
    GenServer.call(via(ref), :liveness, timeout)
  end

  @doc """
  Synchronously invokes an Action on an Actor.
  """
  @spec invoke(any, any, any) :: any
  def invoke(ref, request, opts \\ [])

  def invoke(ref, request, opts) when is_pid(ref) do
    timeout = Keyword.get(opts, :timeout, @default_call_timeout)
    GenServer.call(ref, {:invocation_request, request, opts}, timeout)
  end

  def invoke(ref, request, opts) do
    timeout = Keyword.get(opts, :timeout, @default_call_timeout)
    GenServer.call(via(ref), {:invocation_request, request, opts}, timeout)
  end

  @doc """
  Asynchronously invokes an Action on an Actor.
  """
  @spec invoke_async(any, any, any) :: :ok
  def invoke_async(ref, request, opts \\ [])

  def invoke_async(ref, request, opts) when is_pid(ref) do
    GenServer.cast(ref, {:invocation_request, request, opts})
  end

  def invoke_async(ref, request, opts) do
    GenServer.cast(via(ref), {:invocation_request, request, opts})
  end

  ## Private Functions

  defp parse_packed_response(response) do
    case response do
      {:reply, response, state} -> {:reply, response, EntityState.pack(state)}
      {:reply, response, state, opts} -> {:reply, response, EntityState.pack(state), opts}
      {:stop, reason, state, opts} -> {:stop, reason, EntityState.pack(state), opts}
      {:stop, reason, state} -> {:stop, reason, EntityState.pack(state)}
      {:noreply, state} -> {:noreply, EntityState.pack(state)}
      {:noreply, state, opts} -> {:noreply, EntityState.pack(state), opts}
      {:ok, state} -> {:ok, EntityState.pack(state)}
      {:ok, state, opts} -> {:ok, EntityState.pack(state), opts}
    end
  end

  defp reply_to_noreply({:reply, _response, state}), do: {:noreply, state}
  defp reply_to_noreply({:reply, _response, state, opts}), do: {:noreply, state, opts}
  defp reply_to_noreply({:noreply, state}), do: {:noreply, state}
  defp reply_to_noreply({:noreply, _response, state}), do: {:noreply, state}
  defp reply_to_noreply({:noreply, _response, state, opts}), do: {:noreply, state, opts}

  defp via(name) do
    {:via, Horde.Registry, {Spawn.Cluster.Node.Registry, {__MODULE__, name}}}
  end
end
