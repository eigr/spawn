defmodule Actors.Registry.LoadBalance.Strategies.RoundRobin do
  @moduledoc """
  `RoundRobin` implements the `Actors.Registry.LoadBalance.Strategy` behavior
  by searching the actors using a RoundRobin strategy,
  that is, it will try to distribute the load equally among the nodes.
  """

  @behaviour Actors.Registry.LoadBalance.Strategy

  @impl Actors.Registry.LoadBalance.Strategy
  def next_host(hosts, _opts \\ [])

  def next_host(hosts, _opts) when is_nil(hosts), do: {:not_found, nil, []}

  def next_host([], _opts), do: {:not_found, nil, []}

  def next_host([next_host | rest], _opts), do: {:ok, next_host, rest ++ [next_host]}
end
