defmodule Actors.Registry.LoadBalance.Strategy do
  @moduledoc """
  `LoadBalance.Strategy` Define an interface to allow the search of actors
  in the Distributed Registry.
  """

  @type hosts :: list()
  @type opts :: Keyword.t()

  @callback next_host(hosts, opts) :: {:ok, node(), list()} | {:not_found, nil, []}
end
