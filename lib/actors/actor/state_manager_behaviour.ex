defmodule Actors.Actor.StateManager.Behaviour do
  @callback is_new?(String.t(), any()) :: {:error, term()} | boolean()

  @callback load(String.t()) :: {:ok, term()} | {:not_found, %{}} | {:error, term()}

  @callback save(String.t(), term()) ::
              {:ok, term(), String.t()}
              | {:error, term(), term(), term()}
              | {:error, term(), term()}

  @callback save_async(String.t(), term(), integer()) ::
              {:ok, term(), String.t()}
              | {:error, term(), term(), term()}
              | {:error, term(), term()}
end
