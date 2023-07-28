defmodule Actors.Actor.StateManager.Behaviour do
  @moduledoc """
  `StateManager.Behaviour` Defines behavior that allows an Actor's state
  to be saved to persistent storage using database drivers.
  """

  @callback is_new?(String.t(), any()) :: {:error, term()} | boolean()

  @callback load(String.t()) :: {:ok, term()} | {:not_found, %{}} | {:error, term()}

  @callback save(String.t(), term(), Keyword.t()) ::
              {:ok, term(), String.t()}
              | {:error, term(), term(), term()}
              | {:error, term(), term()}

  @callback save_async(String.t(), term(), Keyword.t()) ::
              {:ok, term(), String.t()}
              | {:error, term(), term(), term()}
              | {:error, term(), term()}
end
