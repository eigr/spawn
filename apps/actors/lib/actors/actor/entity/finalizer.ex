defmodule Actors.Actor.Entity.Finalizer do
  require Logger

  alias Actors.Actor.Entity.EntityState
  alias Actors.Actor.StateManager

  alias Eigr.Functions.Protocol.Actors.{
    Actor,
    ActorId,
    ActorConfiguration,
    ActorDeactivateStrategy,
    ActorState,
    TimeoutStrategy
  }

  @default_deactivate_timeout 90_000

  def handle_deactivate(
        %EntityState{
          actor:
            %Actor{
              actor_id: %ActorId{name: name},
              configuration: %ActorConfiguration{
                deactivate_strategy:
                  %ActorDeactivateStrategy{strategy: deactivate_strategy} =
                    _actor_deactivate_strategy
              }
            } = _actor
        } = state
      ) do
    case Process.info(self(), :message_queue_len) do
      {:message_queue_len, 0} ->
        Logger.debug("Deactivating actor #{name} for timeout")
        {:stop, :normal, state}

      _ ->
        schedule_deactivate(deactivate_strategy)
        {:noreply, state}
    end
  end

  def handle_terminate(
        reason,
        %EntityState{
          actor: %Actor{
            actor_id: %ActorId{name: name},
            state: actor_state,
            configuration: %ActorConfiguration{
              persistent: persistent
            }
          }
        } = _state
      )
      when is_nil(actor_state) or persistent == false do
    Logger.debug("Terminating actor #{name} with reason #{inspect(reason)}")
  end

  def handle_terminate(
        reason,
        %EntityState{
          actor: %Actor{
            actor_id: %ActorId{name: name},
            state: %ActorState{} = actor_state,
            configuration: %ActorConfiguration{
              persistent: true
            }
          }
        } = _state
      ) do
    StateManager.save(name, actor_state)
    Logger.debug("Terminating actor #{name} with reason #{inspect(reason)}")
  end

  def schedule_deactivate(deactivate_strategy, timeout_factor \\ 0),
    do:
      Process.send_after(
        self(),
        :deactivate,
        get_deactivate_interval(deactivate_strategy, timeout_factor)
      )

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

  defp get_deactivate_interval(
         _strategy,
         timeout_factor
       ),
       do: @default_deactivate_timeout + timeout_factor
end
