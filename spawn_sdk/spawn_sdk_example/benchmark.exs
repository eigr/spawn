# Simples tests
# Run with:
# PROXY_CLUSTER_STRATEGY=gossip PROXY_DATABASE_TYPE=mysql PROXY_DATABASE_POOL_SIZE=10 SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= mix run benchmark.exs

require Logger

import SpawnSdkExample

Logger.info("Running Non Parallel Invoke - 5s")

Benchee.run(
  %{
    "Non Parallel Stateful Singleton Actor                  - Get State   " => fn ->
      invok_get_state()
    end,
    "Non Parallel Stateful Singleton Actor                  - Update State" => fn ->
      invoke_update_state()
    end,
    # "Async Non Parallel Stateful Singleton Actor            - Update State" => fn ->
    #   async_invoke_update_state()
    # end,
    # "Non Parallel Stateful Abstract Spawn and Invoke Actor  - Update State" => fn ->
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
      file: "test/benchmark/results/non-parallel-invocations-5s.html", auto_open: false
    },
    Benchee.Formatters.Console
  ],
  save: [path: "test/benchmark/results/non-parallel-invocations-5s.benchee"],
  print: [
    benchmarking: true,
    configuration: true,
    fast_warning: true
  ],
  # unit_scaling: :largest,
  profile_after: false
)

# Logger.info("Running Non Parallel Invoke - 30s")

# Benchee.run(
#   %{
#     "Non Parallel Stateful Singleton Actor                  - Get State   " => fn ->
#       invok_get_state()
#     end,
#     "Non Parallel Stateful Singleton Actor                  - Update State" => fn ->
#       invoke_update_state()
#     end,
#     "Non Parallel Stateful Abstract Spawn and Invoke Actor  - Update State" => fn ->
#       spawn_and_invoke()
#     end,
#     "Non Parallel Stateless Pooled Actor                    - Call Action " => fn ->
#       spawn_invoke_pooled_actors()
#     end
#   },
#   time: 30,
#   parallel: 1,
#   formatters: [
#     {
#       Benchee.Formatters.HTML,
#       file: "test/benchmark/results/non-parallel-invocations-30s.html", auto_open: false
#     },
#     Benchee.Formatters.Console
#   ],
#   save: [path: "test/benchmark/results/non-parallel-invocations-30s.benchee"],
#   print: [
#     benchmarking: true,
#     configuration: true,
#     fast_warning: true
#   ],
#   profile_after: true
# )

# Logger.info("Running Parallel 10x Invoke - 5s")

# #Process.sleep(10000)
# Benchee.run(%{
#   "Parallel Stateful Singleton Actor                  - Get State   " => fn -> invok_get_state() end,
#   "Parallel Stateful Abstract Spawn and Invoke Actor  - Update State" => fn -> spawn_and_invoke() end,
#   "Parallel Stateful Singleton Actor                  - Update State" => fn -> invoke_update_state() end,
#   "Async Non Parallel Stateful Singleton Actor        - Update State" => fn -> async_invoke_update_state() end,
#   #"Parallel Stateless Pooled Actor                    - Call Action " => fn -> spawn_invoke_pooled_actors() end
#   },
#   warmup: 10,
#   parallel: 10,
#   after_scenario: fn _ctx -> Process.sleep(5000) end,
#   formatters: [
#   {
#     Benchee.Formatters.HTML,
#     file: "test/benchmark/results/parallel-invocations-5s.html",
#     auto_open: false
#   },
#     Benchee.Formatters.Console
#   ],
#   save: [path: "test/benchmark/results/parallel-invocations-5s.benchee"],
#   print: [
#     benchmarking: true,
#     configuration: true,
#     fast_warning: true
#   ]
# )
