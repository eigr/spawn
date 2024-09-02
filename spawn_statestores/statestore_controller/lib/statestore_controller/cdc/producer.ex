defmodule StatestoreController.CDC.Producer do
  @moduledoc """

  """
  @callback is_alive?() :: boolean()
  @callback produce(String.t(), any(), Keyword.t()) ::
              nil
              | :ok
              | {:ok, integer}
              | {:error, :closed}
              | {:error, :inet.posix()}
              | {:error, any}
              | :leader_not_available
              | {:error, :cannot_produce, any()}
end
