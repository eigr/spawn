defmodule SpawnSdk do
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

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

  defmodule ActorGroupRef do
    @enforce_keys [:actors]
    defstruct actors: nil, opts: []

    @type t() :: %__MODULE__{
            actors: list(ActorRef.t()),
            opts: Keyword.t() | []
          }
  end

  @doc """
  Invokes a function for a actor_name

  ## Opts

  - `system` this is required
  - `ref` attribute attribute will always lookup to see if the referenced actor is already started or not.
  - `payload` attribute is optional.
  - `action` has default values that you can use to get current actor state
    - get, get_state, Get, getState, GetState

  ## Examples

  ```elixir
  iex> SpawnSdk.invoke(
    "actor_name",
    ref: SpawnSdkExample.Actors.UnamedActor,
    system: "spawn-system",
    action: "sum", # "sum" or :sum
    payload: %Io.Eigr.Spawn.Example.MyBusinessMessage{value: 5}
  )
  {:ok, %Io.Eigr.Spawn.Example.MyBusinessMessage{value: 5}}

  iex> SpawnSdk.invoke("actor_name", system: "spawn-system", action: "get")
  {:ok, %Io.Eigr.Spawn.Example.MyBusinessMessage{value: 5}}
  ```
  """
  @deprecated
  defdelegate invoke(actor_name, invoke_opts), to: SpawnSdk.System.SpawnSystem

  @doc """
  Spawns a Unamed actor

  A Unamed actor means that you can spawn dynamically the same actor for multiple different names.
  It is analog to `DynamicSupervisor`

  ## Opts

  - `system` this is required
  - `actor` which actor you will register first argument to

  ## Examples

  ```elixir
  iex> SpawnSdk.spawn_actor(
    "actor_name",
    system: "spawn-system",
    actor: SpawnSdkExample.Actors.UnamedActor
  )
  ```
  """
  @deprecated
  defdelegate spawn_actor(actor_name, spawn_actor_opts), to: SpawnSdk.System.SpawnSystem
end
