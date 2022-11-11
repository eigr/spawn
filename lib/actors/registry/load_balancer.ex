defmodule Actors.Registry.LoadBalancer do
  @moduledoc """
  `LoadBalance` to call hosts
  """

  @strategy Application.compile_env(
              :spawn,
              :load_blance_strategy,
              Actors.Registry.LoadBalance.Strategies.RoundRobin
            )

  defdelegate next_host(hosts), to: @strategy, as: :next_host
end
