defmodule SpawnSdk.Value do
  defstruct state: nil, value: nil

  @type t :: %__MODULE__{
          state: module(),
          value: module()
        }

  @type value :: __MODULE__.t()

  @type response :: module()

  @type new_state :: module()

  @spec of(value(), response(), new_state()) :: value()
  def of(%SpawnSdk.Value{} = value, response, new_state) do
    struct(value, value: response, state: new_state)
  end

  @spec reply!(value()) :: {:reply, value()}
  def reply!(%SpawnSdk.Value{value: response, state: new_state} = _value)
      when is_nil(response) or is_nil(new_state),
      do: raise("Response Value and New State are required!")

  def reply!(%SpawnSdk.Value{} = value) do
    {:reply, value}
  end
end
