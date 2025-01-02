defmodule Actors.Actor.StateManager.Behaviour do
  @moduledoc """
  `StateManager.Behaviour` Defines behavior that allows an Actor's state
  to be saved to persistent storage using database drivers.
  """

  @type projection_type :: module()
  @type table_name :: String.t()
  @type data :: struct()
  @type query :: String.t()
  @type params :: struct()
  @type opts :: Keyword.t()

  @callback is_new?(String.t(), any()) :: {:error, term()} | boolean()

  @callback load(String.t()) :: {:ok, term()} | {:not_found, %{}} | {:error, term()}

  @callback load(String.t(), number()) :: {:ok, term()} | {:not_found, %{}} | {:error, term()}

  @callback save(String.t(), term(), Keyword.t()) ::
              {:ok, term(), String.t()}
              | {:error, term(), term(), term()}
              | {:error, term(), term()}

  @callback save_async(String.t(), term(), Keyword.t()) ::
              {:ok, term(), String.t()}
              | {:error, term(), term(), term()}
              | {:error, term(), term()}

  @callback projection_create_or_update_table(projection_type(), table_name()) :: :ok

  @callback projection_upsert(projection_type(), table_name(), data()) :: :ok

  @callback projection_query(projection_type(), query(), params(), opts()) ::
              {:error, term()} | {:ok, data()}
end
