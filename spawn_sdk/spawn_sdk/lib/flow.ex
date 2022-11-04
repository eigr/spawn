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
    def to(channel, command, payload \\ nil) do
      command_name = if is_atom(command), do: Atom.to_string(command), else: command

      %__MODULE__{
        channel: channel,
        command: command_name,
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
    defstruct actor_name: nil, command: nil, payload: nil

    @type t :: %__MODULE__{
            actor_name: String.t(),
            command: String.t() | atom(),
            payload: module()
          }

    @type actor_name :: String.t()

    @type command :: String.t() | atom()

    @type payload :: module() | nil

    @spec of() :: list(SideEffect.t())
    def of(), do: []

    @spec effect(list(), actor_name(), command(), payload()) :: list(SideEffect.t())
    def effect(list, actor_name, command, payload \\ nil) do
      effect = to(actor_name, command, payload)
      list ++ [effect]
    end

    @spec to(actor_name(), command(), payload()) :: SideEffect.t()
    def to(actor_name, command, payload \\ nil) do
      command_name = if is_atom(command), do: Atom.to_string(command), else: command

      %__MODULE__{
        actor_name: actor_name,
        command: command_name,
        payload: payload
      }
    end
  end
end
