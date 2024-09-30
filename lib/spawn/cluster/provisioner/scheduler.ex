defmodule Spawn.Cluster.Provisioner.Scheduler do
  alias Spawn.Cluster.ProvisionerPoolSupervisor
  import Spawn.Utils.Common, only: [build_worker_pool_name: 2]

  def schedule_and_invoke(parent, invocation, opts, state, func) when is_function(func) do
    build_worker_pool_name(ProvisionerPoolSupervisor, parent)
    |> FLAME.call(fn -> func.({invocation, opts}, state) end)
  end
end
