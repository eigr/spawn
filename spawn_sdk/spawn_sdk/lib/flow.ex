defmodule SpawnSdk.Flow do
  defmodule SideEffect do
    defstruct actor_name: nil, command: nil, payload: nil

    @type t :: %__MODULE__{
            actor_name: String.t(),
            command: String.t() | atom(),
            payload: module()
          }

    @type actor_name :: String.t()

    @type command :: String.t() | atom()

    @type payload :: module()

    @spec of() :: list(SideEffect.t())
    def of(), do: []

    @spec effect(list(), actor_name(), command(), payload()) :: list(SideEffect.t())
    def effect(list, actor_name, command, payload) do
      effect = to(actor_name, command, payload)
      list ++ [effect]
    end

    @spec to(actor_name(), command(), payload()) :: SideEffect.t()
    def to(actor_name, command, payload) do
      command_name = if is_atom(command), do: Atom.to_string(command), else: command

      %__MODULE__{
        actor_name: actor_name,
        command: command_name,
        payload: payload
      }
    end
  end
end
