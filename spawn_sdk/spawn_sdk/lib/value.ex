defmodule SpawnSdk.Value do
  alias SpawnSdk.Flow.{Broadcast, Pipe, SideEffect}

  defstruct state: nil, value: nil, broadcast: nil, pipe: nil, effects: nil

  @type t :: %__MODULE__{
          state: module(),
          value: module(),
          broadcast: Broadcast.t(),
          pipe: Pipe.t(),
          effects: list(SideEffect.t())
        }

  @type value :: __MODULE__.t()

  @type broadcast :: Broadcast.t()

  @type effects :: list(SideEffect.t())

  @type pipe :: Pipe.t()

  @type response :: module()

  @type new_state :: module()

  @spec of() :: value()
  def of(), do: %SpawnSdk.Value{}

  @spec of(value(), response(), new_state()) :: value()
  def of(%SpawnSdk.Value{} = value, response, new_state) do
    struct(value, value: response, state: new_state)
  end

  @spec state(value(), new_state()) :: value()
  def state(%SpawnSdk.Value{} = value, new_state) do
    struct(value, state: new_state)
  end

  @spec value(value(), response()) :: value()
  def value(%SpawnSdk.Value{} = value, response) do
    struct(value, value: response)
  end

  @spec broadcast(value(), broadcast()) :: value()
  def broadcast(%SpawnSdk.Value{} = value, broadcast) do
    struct(value, broadcast: broadcast)
  end

  @spec effect(value(), effects()) :: value()
  def effect(%SpawnSdk.Value{} = value, effect) do
    struct(value, effects: [effect])
  end

  @spec effects(value(), effects()) :: value()
  def effects(%SpawnSdk.Value{} = value, effects) do
    struct(value, effects: effects)
  end

  @spec pipe(value(), pipe()) :: value()
  def pipe(%SpawnSdk.Value{value: result} = _value, _pipe) when is_nil(result) or result == %{},
    do: raise("Response Value are required!")

  @spec pipe(value(), pipe()) :: value()
  def pipe(%SpawnSdk.Value{} = value, pipe) do
    struct(value, pipe: pipe)
  end

  @spec reply!(value()) :: {:reply, value()}
  def reply!(%SpawnSdk.Value{value: response, state: new_state} = _value)
      when is_nil(response) or is_nil(new_state),
      do: raise("Response Value and New State are required!")

  def reply!(%SpawnSdk.Value{} = value) do
    {:reply, value}
  end

  @spec noreply!(value()) :: {:reply, value()}
  def noreply!(%SpawnSdk.Value{state: new_state} = value, opts \\ []) do
    force = Keyword.get(opts, :force, false)

    if is_nil(new_state) and not force do
      raise("Argumenterror. Response New State are required!")
    end

    {:reply, value}
  end

  def void(%SpawnSdk.Value{} = value) do
    {:reply, value}
  end
end
