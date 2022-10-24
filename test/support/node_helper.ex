defmodule Spawn.NodeHelper do
  @moduledoc """
  This creates peer nodes and connects to current node
  You can limit the CPU cores by spawning with cpu_count flag
  """

  def spawn_peer(node_name, options \\ []) do
    # Turn node into a distributed node with the given long name
    :net_kernel.start([:"primary@127.0.0.1"])

    # Allow spawned nodes to fetch all code from this node
    :erl_boot_server.start([])
    allow_boot(to_charlist("127.0.0.1"))

    spawn_node(:"#{node_name}@127.0.0.1", options)
  end

  def rpc(node, module, function, args) do
    :rpc.block_call(node, module, function, args)
  end

  defp spawn_node(node_host, options) do
    {:ok, node} = :slave.start(to_charlist("127.0.0.1"), node_name(node_host), inet_loader_args())

    rpc(node, :code, :add_paths, [:code.get_path()])

    rpc(node, Application, :ensure_all_started, [:mix])
    rpc(node, Application, :ensure_all_started, [:logger])

    rpc(node, Logger, :configure, [[level: Logger.level()]])
    rpc(node, Mix, :env, [Mix.env()])

    loaded_apps =
      for {app_name, _, _} <- Application.loaded_applications() do
        base = Application.get_all_env(app_name)

        environment =
          options
          |> Keyword.get(:environment, [])
          |> Keyword.get(app_name, [])
          |> Keyword.merge(base, fn _, v, _ -> v end)

        for {key, val} <- environment do
          rpc(node, Application, :put_env, [app_name, key, val])
        end

        app_name
      end

    ordered_apps = Keyword.get(options, :applications, loaded_apps)

    for app_name <- ordered_apps, app_name in loaded_apps do
      rpc(node, Application, :ensure_all_started, [app_name])
    end

    for file <- Keyword.get(options, :files, []) do
      rpc(node, Code, :require_file, [file])
    end

    node
  end

  defp inet_loader_args do
    to_charlist("-loader inet -hosts 127.0.0.1 -setcookie #{:erlang.get_cookie()}")
  end

  defp allow_boot(host) do
    {:ok, ipv4} = :inet.parse_ipv4_address(host)
    :erl_boot_server.add_slave(ipv4)
  end

  defp node_name(node_host) do
    node_host
    |> to_string
    |> String.split("@")
    |> Enum.at(0)
    |> String.to_atom()
  end
end
