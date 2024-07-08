defmodule Spawn.Cluster.Node.Registry do
  @moduledoc """
  Defines a distributed registry for all process.
  """
  alias ProcessHub.Service.ProcessRegistry

  @doc """
  Get Process if this is alive.
  """
  def lookup(system, actor_name) do
    case ProcessRegistry.lookup(system, actor_name) do
      nil ->
        :not_found

      {%{id: ^actor_name, start: {_module, _fun, _args}}, lookups} ->
        pid =
          lookups
          |> Enum.map(fn {_node, pid} -> pid end)
          |> List.first()

        {:ok, pid}

      error ->
        {:error, error}
    end
  end

  @doc """
  Check if Process is alive.
  """
  def is_alive?(mod, actor_name) do
  end

  @doc """
  List all alive PIDs from given registry module.
  """
  @spec list_actor_pids(module()) :: list(pid())
  def list_actor_pids(mod) do
  end
end
