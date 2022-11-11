defmodule Actors.Registry.LoadBalance.Strategies.RoundRobin do
  @behaviour Actors.Registry.LoadBalance.Strategy

  @impl Actors.Registry.LoadBalance.Strategy
  def next_host(hosts, _opts \\ [])

  def next_host(hosts, _opts) when is_nil(hosts), do: {:not_found, nil, []}

  def next_host([], _opts), do: {:not_found, nil, []}

  def next_host([next_host | rest], _opts), do: {:ok, next_host, rest ++ [next_host]}
end
