defmodule SpawnSdk.Flow do
  defmodule Broadcast do
    @moduledoc """
    Actors can also send messages to a group of actors at once as an action callback. This we call Broadcast.

    ### Example using Elixir SDK:
    defmodule Fleet.Actors.Driver do
      use SpawnSdk.Actor,
        kind: :abstract,
        # Set ´driver´ channel for all actors of the same type (Fleet.Actors.Driver)
        channel: "drivers",
        state_type: Fleet.Domain.Driver

      alias Fleet.Domain.{
        Driver,
        OfferRequest,
        OfferResponse,
        Point
      }

      require Logger

      @brain_actor_channel "fleet-controllers"

      defact update_position(%Point{} = position, %Context{state: %Driver{id: name} = driver} = ctx) do
        driver_state = %Driver{driver | position: position}

        %Value{}
        |> Value.of(driver_state, driver_state)
        |> Value.broadcast(
          Broadcast.to(
            @brain_actor_channel,
            "driver_position",
            driver_state
          )
        )
        |> Value.reply!()
      end
    end

    In the case above, every time an Actor "driver" executes the update_position action
    it will send a message to all the actors participating in the channel called "fleet-controllers".

    Broadcasts can also be performed outside the Spawn Actor system,
    using the transport mechanism based on Phoenix.PubSub in memory or
    Phoenix.PubSub over Nats Broker.
    """
    defstruct channel: nil, action: nil, payload: nil

    @type t :: %__MODULE__{
            channel: String.t(),
            action: String.t() | atom(),
            payload: module()
          }

    @type channel :: String.t()

    @type action :: String.t() | atom()

    @type payload :: module() | nil

    @spec to(channel(), action(), payload()) :: Broadcast.t()
    def to(channel, action, payload) do
      action_name = if is_atom(action), do: Atom.to_string(action), else: action

      %__MODULE__{
        channel: channel,
        action: action_name,
        payload: payload
      }
    end

    @spec to(channel(), payload()) :: Broadcast.t()
    def to(channel, payload) do
      %__MODULE__{
        channel: channel,
        payload: payload
      }
    end
  end

  defmodule Pipe do
    @moduledoc """
    Pipe allows the Actor to send its output message directly to another Actor,
    where the Actor that receives the Pipe will be responsible for following the flow from then on.
    This is done as part of the actor's response flow.
    Pipes are detached from the Actor that received the input, that is,
    when you forward a message to another actor through a Pipe,
    the actor that performs the Pipe is free to process another message
    and the actor that is receiving the Pipe is the one who will respond to the original caller.
    """
    defstruct actor_name: nil, action: nil

    @type t :: %__MODULE__{
            actor_name: String.t(),
            action: String.t() | atom()
          }

    @type actor_name :: String.t()

    @type action :: String.t() | atom()

    @spec to(actor_name(), action()) :: Pipe.t()
    def to(actor_name, action) do
      action_name = if is_atom(action), do: Atom.to_string(action), else: action

      %__MODULE__{
        actor_name: actor_name,
        action: action_name
      }
    end
  end

  defmodule Forward do
    @moduledoc """
    Forward allows the Actor to delegate processing of the incoming message to another Actor.
    This is done as part of the actor's response flow.
    Forwards are detached from the Actor that received the input, that is,
    when you forward a message to another actor, the actor that performs the forwarding is free
    to process another message and the actor that is receiving the forwarding will respond
    to the original caller.
    """
    defstruct actor_name: nil, action: nil

    @type t :: %__MODULE__{
            actor_name: String.t(),
            action: String.t() | atom()
          }

    @type actor_name :: String.t()

    @type action :: String.t() | atom()

    @spec to(actor_name(), action()) :: Forward.t()
    def to(actor_name, action) do
      action_name = if is_atom(action), do: Atom.to_string(action), else: action

      %__MODULE__{
        actor_name: actor_name,
        action: action_name
      }
    end
  end

  defmodule SideEffect do
    @moduledoc """
    Actors can also emit side effects to other Actors as part of their response.
    Side effects do not interfere with an actor's request-response flow.
    They will "always" be processed asynchronously and any response sent back from the Actor
    receiving the effect will be ignored by the effector.
    """
    defstruct actor_name: nil, action: nil, payload: nil, scheduled_to: nil

    @type t :: %__MODULE__{
            actor_name: String.t(),
            action: String.t() | atom(),
            payload: module(),
            scheduled_to: integer() | nil
          }

    @type actor_name :: String.t()

    @type action :: String.t() | atom()

    @type payload :: module() | nil

    @spec of() :: list(SideEffect.t())
    def of(), do: []

    @spec effect(list(), actor_name(), action(), payload()) :: list(SideEffect.t())
    def effect(list, actor_name, action, payload \\ nil, opts \\ []) do
      effect = to(actor_name, action, payload, opts)
      list ++ [effect]
    end

    @spec to(actor_name(), action(), payload(), list()) :: SideEffect.t()
    def to(actor_name, action, payload \\ nil, opts \\ []) do
      action_name = if is_atom(action), do: Atom.to_string(action), else: action

      %__MODULE__{
        actor_name: actor_name,
        action: action_name,
        payload: payload,
        scheduled_to: parse_scheduled_to(opts[:delay], opts[:scheduled_to])
      }
    end

    defp parse_scheduled_to(nil, nil), do: nil

    defp parse_scheduled_to(delay_ms, _scheduled_to) when is_integer(delay_ms) do
      scheduled_to = DateTime.add(DateTime.utc_now(), delay_ms, :millisecond)
      parse_scheduled_to(nil, scheduled_to)
    end

    defp parse_scheduled_to(_delay_ms, nil), do: nil

    defp parse_scheduled_to(_delay_ms, scheduled_to) do
      DateTime.to_unix(scheduled_to, :millisecond)
    end
  end
end
