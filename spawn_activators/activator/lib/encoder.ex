defmodule Activator.Encoder do
  @moduledoc """
  Encoder convert one type to another
  """

  @type data :: any()

  @doc """
  Encode data to certain type.
  """
  @callback encode(data()) :: {:ok, any()} | {:error, any()}

  @doc """
  Decode data to certain type.
  """
  @callback decode(data) :: {:ok, term()} | {:error, any()}
end
