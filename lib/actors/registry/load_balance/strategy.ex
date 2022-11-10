defmodule Actors.Registry.LoadBalance.Strategy do
  @type hosts :: list()

  @callback next_host(hosts) :: {:ok, node(), list()} | {:not_found, nil, []}
end
