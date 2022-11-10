defmodule SpawnSdk.Flow do
  defmodule Broadcast do
    defstruct channel: nil, command: nil, payload: nil

    @type t :: %__MODULE__{
            channel: String.t(),
            command: String.t() | atom(),
            payload: module()
          }

    @type channel :: String.t()

    @type command :: String.t() | atom()

    @type payload :: module() | nil

    @spec to(channel(), command(), payload()) :: Broadcast.t()
    def to(channel, command, payload) do
      command_name = if is_atom(command), do: Atom.to_string(command), else: command

      %__MODULE__{
        channel: channel,
        command: command_name,
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
    defstruct actor_name: nil, command: nil

    @type t :: %__MODULE__{
            actor_name: String.t(),
            command: String.t() | atom()
          }

    @type actor_name :: String.t()

    @type command :: String.t() | atom()

    @spec to(actor_name(), command()) :: Pipe.t()
    def to(actor_name, command) do
      command_name = if is_atom(command), do: Atom.to_string(command), else: command

      %__MODULE__{
        actor_name: actor_name,
        command: command_name
      }
    end
  end

  defmodule Forward do
    defstruct actor_name: nil, command: nil

    @type t :: %__MODULE__{
            actor_name: String.t(),
            command: String.t() | atom()
          }

    @type actor_name :: String.t()

    @type command :: String.t() | atom()

    @spec to(actor_name(), command()) :: Forward.t()
    def to(actor_name, command) do
      command_name = if is_atom(command), do: Atom.to_string(command), else: command

      %__MODULE__{
        actor_name: actor_name,
        command: command_name
      }
    end
  end

  defmodule SideEffect do
    defstruct actor_name: nil, command: nil, payload: nil, scheduled_to: nil

    @type t :: %__MODULE__{
            actor_name: String.t(),
            command: String.t() | atom(),
            payload: module(),
            scheduled_to: integer() | nil
          }

    @type actor_name :: String.t()

    @type command :: String.t() | atom()

    @type payload :: module() | nil

    @spec of() :: list(SideEffect.t())
    def of(), do: []

    @spec effect(list(), actor_name(), command(), payload()) :: list(SideEffect.t())
    def effect(list, actor_name, command, payload \\ nil, opts \\ []) do
      effect = to(actor_name, command, payload, opts)
      list ++ [effect]
    end

    @spec to(actor_name(), command(), payload(), list()) :: SideEffect.t()
    def to(actor_name, command, payload \\ nil, opts \\ []) do
      command_name = if is_atom(command), do: Atom.to_string(command), else: command

      %__MODULE__{
        actor_name: actor_name,
        command: command_name,
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
