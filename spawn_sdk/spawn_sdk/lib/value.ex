defmodule SpawnSdk.Value do
  @moduledoc """
  `Value` is a declarative DSL that provides the Domain Driven aspect of the Spawn technology.
  It is through a Value that the user can configure the proxy to carry out
  the infrastructure tasks and from which it provides all the Worflows.
  """
  alias SpawnSdk.Flow.{Broadcast, Pipe, Forward, SideEffect}

  defstruct state: nil,
            value: nil,
            broadcast: nil,
            pipe: nil,
            forward: nil,
            effects: nil,
            tags: nil

  @type t :: %__MODULE__{
          state: module(),
          value: module(),
          tags: map(),
          broadcast: Broadcast.t(),
          pipe: Pipe.t(),
          forward: Forward.t(),
          effects: list(SideEffect.t())
        }

  @type value :: __MODULE__.t()

  @type broadcast :: Broadcast.t()

  @type effects :: list(SideEffect.t())

  @type pipe :: Pipe.t()

  @type forward :: Forward.t()

  @type response :: module()

  @type new_state :: module()

  @type tags :: map()

  @spec of() :: value()
  def of(), do: %SpawnSdk.Value{}

  @spec of(response(), new_state()) :: value()
  def of(response, new_state) do
    struct(%SpawnSdk.Value{}, value: response, state: new_state)
  end

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

  @spec response(value(), response()) :: value()
  def response(%SpawnSdk.Value{} = value, response) do
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
  def pipe(%SpawnSdk.Value{} = value, pipe) do
    struct(value, pipe: pipe)
  end

  @spec forward(value(), forward()) :: value()
  def forward(%SpawnSdk.Value{} = value, forward) do
    struct(value, forward: forward)
  end

  @spec tags(value(), tags()) :: value()
  def tags(%SpawnSdk.Value{} = value, tags) do
    struct(value, tags: tags)
  end

  @spec reply!(value()) :: {:reply, value()}
  def reply!(%SpawnSdk.Value{state: new_state} = _value)
      when is_nil(new_state),
      do: raise("Response New State are required!")

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

  @spec noreply_state!(new_state()) :: {:reply, value()}
  def noreply_state!(state) do
    %__MODULE__{}
    |> state(state)
    |> noreply!()
  end

  @spec void() :: {:reply, value()}
  def void do
    {:reply, %SpawnSdk.Value{}}
  end

  @spec void(value()) :: {:reply, value()}
  def void(%SpawnSdk.Value{} = value) do
    {:reply, value}
  end
end
