defmodule SpawnSdk.System do
  @type actor_name :: String.t()

  @type actor_mod :: module()

  @type actors :: list(actor_mod())

  @type system :: String.t()

  @type command :: String.t()

  @type payload :: struct()

  @type invoke_opts :: [
          command: command(),
          lazy_spawn: actor_mod(),
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
