defmodule Activator.Encoder do
  @moduledoc """
  Encoder convert one type to another
  """

  @type data :: binary()

  @type source :: String.t()

  @type id :: String.t()

  @doc """
  Encode data to certain type.
  """
  @callback encode(data()) :: {:ok, any()} | {:error, any()}

  @doc """
  Decode data to certain type.
  """
  @callback decode(data) :: {:ok, source(), id(), term()} | {:error, any()}
end
