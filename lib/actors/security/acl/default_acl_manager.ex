defmodule Actors.Security.Acl.DefaultAclManager do
  @doc """
  `DefaultAclManager`
  """
  alias Actors.Security.Acl.Policy

  alias Actors.Security.Acl.Rules.AclEvaluator
  import Spawn.Utils.Common, only: [to_existing_atom_or_new: 1]

  @behaviour Actors.Security.Acl

  @impl true
  def load_acl_policies(base_policies_path) do
    case Agent.start_link(fn -> %{} end, name: __MODULE__) do
      {:ok, _pid} ->
        Agent.get_and_update(__MODULE__, fn policies ->
          update_policies(base_policies_path, policies)
        end)

      {:error, {:already_started, _pid}} ->
        Agent.get(__MODULE__, fn policies -> policies end)
    end
  end

  @impl true
  def get_policies!(), do: Agent.get(__MODULE__, fn policies -> policies end)

  @impl true
  def is_authorized?(policies, invocation) do
    Enum.any?(policies, fn policy -> evaluate(policy, invocation) end)
  end

  defp evaluate(policy, invocation), do: AclEvaluator.eval(policy, invocation)

  defp update_policies(path, policies) do
    if policies == %{} do
      policies = load_policies(path)
      {policies, policies}
    else
      {policies, policies}
    end
  end

  defp load_policies(base_policies_path) do
    policies =
      Path.wildcard("#{base_policies_path}/*.policy")
      |> Enum.map(fn file -> {file, from_file_to_map(file)} end)
      |> Enum.map(fn {file, data} ->
        %Policy{
          name: get_file_name(file),
          type: Map.get(data, :type, :allow),
          actors: Map.get(data, :actors, ["*"]),
          actions: Map.get(data, :actions, ["*"]),
          actor_systems: Map.get(data, :actor_systems, ["*"])
        }
      end)

    if length(policies) > 0, do: policies, else: [get_default_policy()]
  end

  defp get_default_policy() do
    %Policy{
      name: "default",
      type: :allow,
      actors: ["*"],
      actions: ["*"],
      actor_systems: ["*"]
    }
  end

  defp get_file_name(file) do
    Path.basename(file)
    |> String.replace(".policy", "")
    |> String.trim()
  end

  defp from_file_to_map(path) do
    if File.exists?(path) do
      File.stream!(path)
      |> Stream.map(fn line ->
        [key | value] = String.split(line, ":")
        key = to_existing_atom_or_new(key)

        value =
          case key do
            :type ->
              List.first(value)
              |> String.replace("\n", "")
              |> String.replace("\"", "")
              |> String.trim()
              |> String.downcase()
              |> to_existing_atom_or_new()

            _ ->
              value
              |> Enum.map(fn elem ->
                String.replace(elem, "\n", "")
                |> String.trim()
              end)
          end

        {key, value}
      end)
      |> Enum.into(%{})
    else
      %{}
    end
  end
end
