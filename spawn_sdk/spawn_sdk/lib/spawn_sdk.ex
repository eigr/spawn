defmodule SpawnSdk do
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  @doc """
  Invokes a function for a actor_name

  ## Opts

  - `system` this is required
  - `ref` attribute attribute will always lookup to see if the referenced actor is already started or not.
  - `payload` attribute is optional.
  - `command` has default values that you can use to get current actor state
    - get, get_state, Get, getState, GetState

  ## Examples

  ```elixir
  iex> SpawnSdk.invoke(
    "actor_name",
    ref: SpawnSdkExample.Actors.AbstractActor,
    system: "spawn-system",
    command: "sum", # "sum" or :sum
    payload: %Io.Eigr.Spawn.Example.MyBusinessMessage{value: 5}
  )
  {:ok, %Io.Eigr.Spawn.Example.MyBusinessMessage{value: 5}}

  iex> SpawnSdk.invoke("actor_name", system: "spawn-system", command: "get")
  {:ok, %Io.Eigr.Spawn.Example.MyBusinessMessage{value: 5}}
  ```
  """
  defdelegate invoke(actor_name, invoke_opts), to: SpawnSdk.System.SpawnSystem

  @doc """
  Spawns a abstract actor

  A abstract actor means that you can spawn dynamically the same actor for multiple different names.
  It is analog to `DynamicSupervisor`

  ## Opts

  - `system` this is required
  - `actor` which actor you will register first argument to

  ## Examples

  ```elixir
  iex> SpawnSdk.spawn_actor(
    "actor_name",
    system: "spawn-system",
    actor: SpawnSdkExample.Actors.AbstractActor
  )
  ```
  """
  defdelegate spawn_actor(actor_name, spawn_actor_opts), to: SpawnSdk.System.SpawnSystem

  defmodule ActorRef do
    @enforce_keys [:system, :name]
    defstruct system: nil, name: nil, opts: []

    @type t() :: %__MODULE__{
            system: String.t(),
            name: String.t(),
            opts: Keyword.t() | []
          }
  end

  defmodule ActorChannel do
    @enforce_keys [:channel]
    defstruct channel: nil, opts: []

    @type t() :: %__MODULE__{
            channel: String.t(),
            opts: Keyword.t() | []
          }
  end

  defmodule ActorGroup do
    @enforce_keys [:actors]
    defstruct actors: nil, opts: []

    @type t() :: %__MODULE__{
            actors: list(ActorRef.t()),
            opts: Keyword.t() | []
          }
  end

  defmodule Actor do
    @type system :: String.t()
    @type actor :: String.t()
    @type opts :: Keyword.t()

    @type group :: ActorGroup.t()

    @spec ref(system(), actor(), opts()) :: ActorRef.t()
    def ref(system, name, opts \\ []),
      do: %SpawnSdk.ActorRef{system: system, name: name, opts: opts}

    @spec group(list(ActorRef), opts()) :: ActorRef.t()
    def group(actors, opts \\ []) when is_list(actors),
      do: %SpawnSdk.ActorGroup{actors: actors, opts: opts}

    @spec channel(ActorChannel.t(), opts()) :: :ok
    def channel(channel, opts), do: %SpawnSdk.ActorChannel{channel: channel, opts: opts}

    @spec invoke(ActorRef.t() | ActorGroup.t(), any(), opts()) :: any()
    def invoke(ref, data, opts \\ [])

    def invoke(%ActorRef{} = _ref, _data, _opts) do
    end

    def invoke(%ActorGroup{} = _group, _data, _opts) do
    end

    @spec cast(ActorRef.t() | ActorGroup.t(), any(), opts()) :: :ok
    def cast(ref, data, opts \\ [])

    def cast(%ActorRef{} = _ref, _data, _opts) do
    end

    def cast(%ActorGroup{} = _group, _data, _opts) do
    end

    @spec pub(ActorChannel.t(), any(), opts()) :: :ok
    def pub(channel, data, opts \\ [])

    def pub(%ActorChannel{} = _channel, _data, _opts) do
    end
  end
end
