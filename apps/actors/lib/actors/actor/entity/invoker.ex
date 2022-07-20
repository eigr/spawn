defmodule Actors.Actor.Entity.Invoker do
  require Logger

  alias Actors.Actor.Entity.EntityState
  alias Actors.Actor.StateManager

  alias Eigr.Functions.Protocol.Actors.{
    Actor,
    ActorId,
    ActorState
  }

  alias Eigr.Functions.Protocol.{
    Context,
    ActorInvocation,
    ActorInvocationResponse,
    InvocationRequest,
    Value
  }

  def handle_invocation(
        %InvocationRequest{
          actor_id: %ActorId{name: _name} = actor,
          command_name: command,
          value: payload
        } = _invocation,
        %EntityState{
          actor: %Actor{state: current_state = _actor_state} = _state_actor
        } = state
      )
      when is_nil(current_state) do
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
          actor_id: %ActorId{} = actor,
          command_name: command,
          value: payload
        } = _invocation,
        %EntityState{
          actor: %Actor{state: %ActorState{state: current_state} = _actor_state} = _state_actor
        } = state
      ) do
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
