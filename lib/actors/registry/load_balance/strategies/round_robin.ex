defmodule Actors.Registry.LoadBalance.Strategies.RoundRobin do
  @behaviour Actors.Registry.LoadBalance.Strategy

  @impl Actors.Registry.LoadBalance.Strategy
  def next_host(hosts) when is_nil(hosts), do: {:not_found, nil, []}

  def next_host([]), do: {:not_found, nil, []}

  def next_host([next_host | rest]), do: {:ok, next_host, rest ++ [next_host]}
end
