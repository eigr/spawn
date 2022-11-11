defmodule Actors.Registry.LoadBalance.Strategy do
  @type hosts :: list()
  @type opts :: Keyword.t()

  @callback next_host(hosts, opts) :: {:ok, node(), list()} | {:not_found, nil, []}
end
