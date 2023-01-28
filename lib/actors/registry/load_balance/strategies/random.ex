defmodule Actors.Registry.LoadBalance.Strategies.Random do
  @moduledoc """
  `Random` implements the `Actors.Registry.LoadBalance.Strategy` behavior
  by searching the actors randomly, that is,
  if you have registered the same actor in N nodes and try to invoke it,
  the Registry can, if configured,
  use the random strategy to locate one of them in any of the nodes in a random way,
  as the name suggests.
  """

  @behaviour Actors.Registry.LoadBalance.Strategy

  @impl Actors.Registry.LoadBalance.Strategy
  def next_host(hosts, opts \\ [])

  def next_host(hosts, _opts) when is_nil(hosts), do: {:not_found, nil, []}

  def next_host([], _opts), do: {:not_found, nil, []}

  def next_host(hosts, _opts) when is_list(hosts) and length(hosts) > 0 do
    {:ok, Enum.random(hosts), hosts}
  end
end
