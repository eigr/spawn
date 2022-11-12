defmodule Actors.Actor.Interface.Http do
  use Actors.Actor.Interface
  require Logger

  alias Actors.{
    Actor.Entity.EntityState,
    Node.Client
  }

  alias Eigr.Functions.Protocol.Actors.{
    Actor,
    ActorState
  }

  alias Eigr.Functions.Protocol.{
    Context,
    ActorInvocation,
    ActorInvocationResponse
  }

  alias Google.Protobuf.Any

  @impl true
  def invoke_host(
        %ActorInvocation{
          actor_name: name,
          actor_system: system,
          command_name: command,
          caller: caller
        } = payload,
        %EntityState{
          actor: %Actor{state: actor_state, id: actor_id, commands: commands}
        } = state,
        default_actions
      ) do
    if Enum.member?(default_actions, command) and
         not Enum.any?(default_actions, fn action ->
           Enum.any?(commands, fn c -> c.name == action end)
         end) do
      current_state = Map.get(actor_state || %{}, :state)

      context =
        if is_nil(current_state),
          do: Context.new(caller: caller, self: actor_id, state: Any.new()),
          else: Context.new(caller: caller, self: actor_id, state: current_state)

      resp =
        ActorInvocationResponse.new(
          actor_name: name,
          actor_system: system,
          updated_context: context,
          payload: current_state
        )

      {:ok, resp, state}
    else
      payload
      |> ActorInvocation.encode()
      |> Client.invoke_host_actor()
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
end
