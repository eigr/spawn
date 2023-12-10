# Simples tests
# Run with:
# PROXY_CLUSTER_STRATEGY=gossip PROXY_DATABASE_TYPE=mysql PROXY_DATABASE_POOL_SIZE=10 SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= iex --name spawn_actors_node@127.0.0.1 -S mix run benchmark.exs

require Logger

import SpawnSdkExample

Logger.info("Running Non Parallel Invoke - 10s")

Benchee.run(
  %{
    "Non Parallel Actor       - Get State   " => fn ->
      invok_get_state()
    end,
    "Non Parallel Actor       - Update State" => fn ->
      invoke_update_state()
    end,
    "Async Non Parallel Actor - Update State" => fn ->
      async_invoke_update_state()
    end,
    # "Non Parallel Unnamed Spawn and Invoke Actor  - Update State" => fn ->
    #   spawn_and_invoke()
    # end
    # "Non Parallel Stateless Pooled Actor                    - Call Action " => fn ->
    #   spawn_invoke_pooled_actors()
    # end
  },
  time: 10,
  parallel: 1,
  formatters: [
    {
      Benchee.Formatters.HTML,
      file: "test/benchmark/results/non-parallel-invocations-10s.html", auto_open: true
    },
    Benchee.Formatters.Console
  ],
  save: [path: "test/benchmark/results/non-parallel-invocations-10s.benchee"],
  print: [
    benchmarking: true,
    configuration: true,
    fast_warning: true
  ],
  #unit_scaling: :largest,
  profile_after: true
)

# Logger.info("Running Parallel Invoke - 10s")

# Benchee.run(
#   %{
#     "Non Parallel Actor       - Get State   " => fn ->
#       invok_get_state()
#     end,
#     "Non Parallel Actor       - Update State" => fn ->
#       invoke_update_state()
#     end,
#     "Async Non Parallel Actor - Update State" => fn ->
#       async_invoke_update_state()
#     end,
#     # "Non Parallel Unnamed Spawn and Invoke Actor  - Update State" => fn ->
#     #   spawn_and_invoke()
#     # end
#     # "Non Parallel Stateless Pooled Actor                    - Call Action " => fn ->
#     #   spawn_invoke_pooled_actors()
#     # end
#   },
#   time: 10,
#   parallel: 8,
#   formatters: [
#     {
#       Benchee.Formatters.HTML,
#       file: "test/benchmark/results/parallel-invocations-10s.html", auto_open: false
#     },
#     Benchee.Formatters.Console
#   ],
#   save: [path: "test/benchmark/results/parallel-invocations-10s.benchee"],
#   print: [
#     benchmarking: true,
#     configuration: true,
#     fast_warning: true
#   ],
#   #unit_scaling: :largest,
#   profile_after: true
# )
