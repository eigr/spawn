defmodule Spawn.Cluster.Provisioner.Scheduler do
  @moduledoc """
  The `Spawn.Cluster.Provisioner.Scheduler` module is responsible for scheduling tasks and invoking functions in a distributed actor system.
  It handles creating worker pools and executing functions with the given task configuration.

  This module also contains an implementation of the `Executor` protocol for the `SpawnTask` struct,
  defining the execution behavior for tasks in the context of provisioning actors in the cluster.
  """

  alias Spawn.Cluster.Provisioner.SpawnTask
  alias Spawn.Cluster.ProvisionerPoolSupervisor
  import Spawn.Utils.Common, only: [build_worker_pool_name: 2]

  defimpl Spawn.Cluster.Provisioner.Executor, for: Spawn.Cluster.Provisioner.SpawnTask do
    @doc """
    Defines the `Executor` protocol for the `SpawnTask` struct.

    This implementation handles the execution of a given function (`func`) in the context of a task,
    using the specified actor name, invocation details, options (`opts`), and state.

    The task is executed through a worker pool, created using the `build_worker_pool_name/2` function,
    and the function is invoked with the `{invocation, opts}` tuple and the current state.

    ## Parameters

    - `%SpawnTask{}`: The task struct containing details about the actor provisioning process.
    - `func`: The function to be invoked, which takes the task's `invocation`, `opts`, and `state`.

    ## Returns

    The result of executing the provided function within the context of the actor provisioning system.
    """
    def execute(
          %SpawnTask{actor_name: actor_name, invocation: invocation, opts: opts, state: state},
          func
        )
        when is_function(func) do
      build_worker_pool_name(ProvisionerPoolSupervisor, actor_name)
      |> FLAME.call(fn -> func.({invocation, opts}, state) end)
    end
  end

  @doc """
  Schedules and invokes a task for actor provisioning in another k8s POD.

  This function wraps the scheduling logic by leveraging the `Executor` protocol to execute the provided
  function (`func`). The function is called with the `invocation`, `opts`, and `state` details encapsulated in a `SpawnTask` struct.

  ## Parameters

    - `actor_name`: The actor name reference used to create the worker pool for the task execution.
    - `invocation`: The details of the invocation, typically containing metadata about the actor's execution.
    - `opts`: Options passed along with the task, which may modify how the invocation is performed.
    - `state`: The current state of the process, to be passed to the function being invoked.
    - `func`: A function that will be called with the `{invocation, opts}` tuple and the current `state`.

  ## Example

  ```elixir
  task = %SpawnTask{
    actor: actor,
    invocation: invocation,
    opts: opts,
    state: state
  }

  Spawn.Cluster.Provisioner.Scheduler.schedule_and_invoke(task, &some_function/2)
  """
  def schedule_and_invoke(task, func) when is_function(func) do
    Spawn.Cluster.Provisioner.Executor.execute(task, func)
  end
end
