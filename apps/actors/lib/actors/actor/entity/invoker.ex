defmodule Actors.Actor.Entity.Invoker do
  require Logger

  alias Actors.Actor.Entity.EntityState
  alias Actors.Actor.StateManager

  alias Eigr.Functions.Protocol.Actors.{
    Actor,
    ActorId,
    ActorConfiguration,
    ActorSnapshotStrategy,
    ActorState,
    AfterCallCommandStrategy,
    BeforeCallCommandStrategy,
    TimeoutStrategy,
    UserDefinedStrategy
  }

  alias Eigr.Functions.Protocol.{
    Context,
    ActorInvocation,
    ActorInvocationResponse,
    Forward,
    InvocationRequest,
    Pipe,
    Value
  }

  def handle_invocation(
        %InvocationRequest{
          actor_id: %ActorId{resource: actor_ref} = actor,
          command_name: command,
          value: payload
        } = _invocation,
        %EntityState{
          actor:
            %Actor{
              state: current_state = _actor_state,
              configuration: %ActorConfiguration{
                snapshot_strategy: %ActorSnapshotStrategy{strategy: strategy} = _snapshot_strategy
              }
            } = state_actor,
          state_hash: hash
        } = state
      )
      when is_nil(current_state) do
    checkpoint_before(strategy, hash, actor_ref, state_actor)

    payload =
      ActorInvocation.new(
        actor_id: actor,
        command_name: command,
        value: payload,
        current_context: Context.new()
      )
      |> ActorInvocation.encode()

    case Actors.Node.Client.invoke_host_actor(payload) do
      {:ok, %Tesla.Env{body: ""}} ->
        Logger.error("User Function Actor response Invocation body is empty")
        {:error, :no_content}

      {:ok, %Tesla.Env{body: nil}} ->
        Logger.error("User Function Actor response Invocation body is nil")
        {:error, :no_content}

      {:ok, %Tesla.Env{body: body}} ->
        with %ActorInvocationResponse{
               value: %Value{context: %Context{} = user_ctx} = _value
             } = resp <- ActorInvocationResponse.decode(body) do
          checkpoint_after(strategy, hash, actor_ref, state_actor)
          {:reply, {:ok, resp}, update_state(state, user_ctx)}
        else
          error ->
            Logger.error("Error on parse response #{inspect(error)}")
            {:reply, {:error, :invalid_content}, state}
        end

      {:error, reason} ->
        Logger.error("User Function Actor Invocation Error: #{inspect(reason)}")
        {:reply, {:error, reason}, state}

      error ->
        Logger.error("User Function Actor Invocation Unknown Error")
        {:reply, {:error, error}, state}
    end
  end

  def handle_invocation(
        %InvocationRequest{
          actor_id: %ActorId{resource: actor_ref} = actor,
          command_name: command,
          value: payload
        } = _invocation,
        %EntityState{
          actor:
            %Actor{
              state: %ActorState{state: current_state} = _actor_state,
              configuration: %ActorConfiguration{
                snapshot_strategy: %ActorSnapshotStrategy{strategy: strategy} = _snapshot_strategy
              }
            } = state_actor,
          state_hash: hash
        } = state
      ) do
    checkpoint_before(strategy, hash, actor_ref, state_actor)

    payload =
      ActorInvocation.new(
        actor_id: actor,
        command_name: command,
        value: payload,
        current_context: Context.new(state: current_state)
      )
      |> ActorInvocation.encode()

    case Actors.Node.Client.invoke_host_actor(payload) do
      {:ok, %Tesla.Env{body: ""}} ->
        Logger.error("User Function Actor response Invocation body is empty")
        {:error, :no_content}

      {:ok, %Tesla.Env{body: nil}} ->
        Logger.error("User Function Actor response Invocation body is nil")
        {:error, :no_content}

      {:ok, %Tesla.Env{body: body}} ->
        with %ActorInvocationResponse{
               value: %Value{context: %Context{} = user_ctx} = _value
             } = resp <- ActorInvocationResponse.decode(body) do
          # Handle result and workflows
          handle_result(resp)

          # Check persistence strategies and save state if necessary
          checkpoint_after(strategy, hash, actor_ref, state_actor)
          {:reply, {:ok, resp}, update_state(state, user_ctx)}
        else
          error ->
            Logger.error("Error on parse response #{inspect(error)}")
            {:reply, {:error, :invalid_content}, state}
        end

      {:error, reason} ->
        Logger.error("User Function Actor Invocation Error: #{inspect(reason)}")
        {:reply, {:error, reason}, state}

      error ->
        Logger.error("User Function Actor Invocation Unknown Error")
        {:reply, {:error, error}, state}
    end
  end

  defp handle_result(%ActorInvocationResponse{workflow: workflow, effects: _effects} = _result)
       when is_nil(workflow) or workflow == %{} do
    # Handle simple result without workflows
  end

  defp handle_result(
         %ActorInvocationResponse{
           workflow:
             {:forward,
              %Forward{actor_id: target_actor, command_name: command, value: target_value}},
           effects: effects
         } = result
       ) do
    # Handle forward result
  end

  defp handle_result(
         %ActorInvocationResponse{
           value: value,
           workflow: {:pipe, %Pipe{actor_id: target_actor, command_name: command}},
           effects: effects
         } = result
       ) do
    # Handle pipe result
  end

  defp checkpoint_after(strategy, hash, _actor_ref, _actor)
       when is_nil(strategy) or strategy == %{} or is_nil(hash),
       do: :ok

  defp checkpoint_after({:after_command, %AfterCallCommandStrategy{}}, hash, actor_ref, actor) do
    if StateManager.is_new?(hash, actor.state) do
      Logger.debug("AfterCallCommandStrategy triggered. Snapshotting actor #{actor_ref}")
      StateManager.save_async(actor_ref, actor.state)
    end

    :ok
  end

  defp checkpoint_after({:timeout, %TimeoutStrategy{}}, _hash, _actor_ref, _actor), do: :ok

  defp checkpoint_after({:user_defined, %UserDefinedStrategy{}}, _hash, _actor_ref, _actor),
    do: :ok

  defp checkpoint_after(
         {:before_command, %BeforeCallCommandStrategy{}},
         _hash,
         _actor_ref,
         _actor
       ),
       do: :ok

  defp checkpoint_before(strategy, hash, _actor_ref, _actor)
       when is_nil(strategy) or strategy == %{} or is_nil(hash),
       do: :ok

  defp checkpoint_before(
         {:after_command, %AfterCallCommandStrategy{}},
         _hash,
         _actor_ref,
         _actor
       ),
       do: :ok

  defp checkpoint_before({:timeout, %TimeoutStrategy{}}, _hash, _actor_ref, _actor), do: :ok

  defp checkpoint_before({:user_defined, %UserDefinedStrategy{}}, _hash, _actor_ref, _actor),
    do: :ok

  defp checkpoint_before({:before_command, %BeforeCallCommandStrategy{}}, hash, actor_ref, actor) do
    if StateManager.is_new?(hash, actor.state) do
      Logger.debug("BeforeCallCommandStrategy triggered. Snapshotting actor #{actor_ref}")
      StateManager.save_async(actor_ref, actor.state)
    end

    :ok
  end

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
           actor: %Actor{state: %ActorState{} = actor_state} = actor
         } = state,
         %Context{state: updated_state} = _user_ctx
       ) do
    new_state = %{actor_state | state: updated_state}
    %{state | actor: %{actor | state: new_state}}
  end
end
