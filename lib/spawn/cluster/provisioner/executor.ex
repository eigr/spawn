defprotocol Spawn.Cluster.Provisioner.Executor do
  @doc "Executes a task"
  def execute(task, func)
end
