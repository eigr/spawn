defmodule Statestores.Adapters.LookupBehaviour do
  @moduledoc """
  `LookupBehaviour` defines how system get clustered actors info.
  """
  @callback get(any()) :: any()

  @callback set(any()) :: {:error, any()} | {:ok, any()}
end
