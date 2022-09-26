defmodule SpawnSdk.System do
  @type actor_name :: String.t()

  @type actor_mod :: module()

  @type actors :: list(actor_mod())

  @type system :: String.t()

  @type command :: String.t()

  @type payload :: struct()

  @type options :: [
          input_type: module(),
          output_type: module(),
          async: boolean()
        ]

  @callback register(system(), actors()) :: :ok | {:error, term()}

  @callback spawn(actor_name(), actor_mod()) :: {:ok, term()} | {:error, term()}

  @callback invoke(actor_name(), command(), payload(), options()) ::
              {:ok, term()} | {:error, term()}
end
