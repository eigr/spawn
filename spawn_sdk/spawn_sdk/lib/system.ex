defmodule SpawnSdk.System do
  @moduledoc """
  `System` defines the general behavior of the Spawn actor system.
  It is through System implementations that the user can register, invoke,
  and perform other activities with their Actors.
  """
  @type actor_name :: String.t()

  @type actor_mod :: module()

  @type actors :: list(actor_mod())

  @type system :: String.t()

  @type action :: String.t()

  @type payload :: struct()

  @type invoke_opts :: [
          action: action(),
          ref: actor_mod(),
          payload: payload(),
          system: system(),
          async: boolean()
        ]

  @type spawn_actor_opts :: [
          actor: actor_mod(),
          system: system()
        ]

  @callback register(system(), actors()) :: :ok | {:error, term()}

  @callback spawn_actor(actor_name(), spawn_actor_opts()) :: {:ok, term()} | {:error, term()}

  @callback invoke(actor_name(), invoke_opts()) ::
              {:ok, term()} | {:error, term()}
end
