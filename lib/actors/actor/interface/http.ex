defmodule Actors.Actor.Interface.Http do
  @moduledoc """
  `Http` is responsible for the communication between the Proxy and the Host application
  when using the HTTP protocol.
  """
  use Actors.Actor.Interface
  require Logger

  alias Actors.{
    Actor.Entity.EntityState,
    Node.Client
  }

  alias Eigr.Functions.Protocol.Actors.{
    Actor,
    ActorId
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
          actor: %ActorId{name: name, system: system},
          command_name: command,
          caller: caller
        } = payload,
        %EntityState{
          actor: %Actor{state: actor_state, id: actor_id, commands: commands}
        } = state,
        default_actions
      ) do
    if Enum.member?(default_actions, command) and
         not Enum.any?(default_actions, fn action -> contains_action?(commands, action) end) do
      current_state = Map.get(actor_state || %{}, :state)
      current_tags = Map.get(actor_state || %{}, :tags, %{})

      context =
        if is_nil(current_state),
          do: %Context{caller: caller, self: actor_id, state: Any.new(), tags: current_tags},
          else: %Context{caller: caller, self: actor_id, state: current_state, tags: current_tags}

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
          case ActorInvocationResponse.decode(body) do
            %ActorInvocationResponse{
              updated_context: %Context{} = user_ctx
            } = resp ->
              {:ok, resp, update_state(state, user_ctx)}

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

  defp contains_action?(commands, action), do: Enum.any?(commands, fn c -> c.name == action end)

  defp update_state(%EntityState{} = state, %Context{} = ctx) do
    actor = state.actor
    actor_state = actor.state

    cond do
      is_nil(actor_state) ->
        state

      true ->
        new_actor_state =
          actor_state
          |> Map.put(:state, ctx.state || actor_state.state)
          |> Map.put(:tags, ctx.tags || actor_state.tags || %{})

        %{state | actor: %{actor | state: new_actor_state}}
    end
  end
end
