defmodule Spawn.Cluster.ProvisionerPoolSupervisor do
  @moduledoc false
  use Supervisor
  require Logger

  import Spawn.Utils.Common, only: [build_worker_pool_name: 2]

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    actor_configs =
      System.get_env("SPAWN_PROXY_TASK_CONFIG", "")
      |> parse_config()

    env = get_environment()

    children =
      Enum.map(actor_configs, fn cfg ->
        Logger.info("Setup Task Actor with config: #{inspect(cfg)}")

        cfg
        |> build_pod_template()
        |> build_flame_pool(cfg, env)
      end)

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp parse_config(""), do: []

  defp parse_config(encoded_cfg) do
    encoded_cfg
    |> Base.decode32!()
    |> Jason.decode!()
    |> Map.get("taskActors", [])
  end

  defp get_environment do
    case System.get_env("MIX_ENV", "dev") do
      "prod" -> :prod
      env -> String.to_atom(env)
    end
  end

  defp build_pod_template(%{"topology" => topology} = _cfg) do
    %{}
    |> maybe_put_node_selector(topology)
    |> maybe_put_toleration(topology)
  end

  defp build_pod_template(_cfg), do: %{}

  defp maybe_put_node_selector(template, %{"nodeSelector" => selector}) do
    Map.merge(template, %{
      "metadata" => %{
        "labels" => %{"io.eigr.spawn/worker" => "true"}
      },
      "spec" => %{"nodeSelector" => selector}
    })
  end

  defp maybe_put_node_selector(template, _topology), do: template

  defp maybe_put_toleration(template, %{"tolerations" => toleration}) do
    Map.merge(template, %{
      "metadata" => %{
        "labels" => %{"io.eigr.spawn/worker" => "true"}
      },
      "spec" => %{"tolerations" => toleration}
    })
  end

  defp maybe_put_toleration(template, _topology), do: template

  defp build_flame_pool(pod_template, %{"actorName" => name} = cfg, :prod) do
    pool_name = build_worker_pool_name(__MODULE__, name)
    Logger.info("Create pool for Actor #{name}. Pool Name #{inspect(pool_name)}")

    opts =
      [
        name: pool_name,
        backend: {FLAMEK8sBackend, runner_pod_tpl: pod_template},
        log: :debug
      ] ++ get_worker_pool_config(cfg)

    {FLAME.Pool, opts}
  end

  defp build_flame_pool(_pod_template, %{"actorName" => name} = cfg, _env) do
    pool_name = build_worker_pool_name(__MODULE__, name)
    Logger.info("Creating default pool with name #{inspect(pool_name)}")

    opts =
      [
        name: pool_name,
        backend: FLAME.LocalBackend,
        log: :debug
      ] ++ get_worker_pool_config(cfg)

    {FLAME.Pool, opts}
  end

  defp build_flame_pool(_pod_template, cfg, _env) do
    pool_name = Module.concat(__MODULE__, "Default")
    Logger.info("Creating default pool with name #{inspect(pool_name)}")

    opts =
      [
        name: pool_name,
        backend: FLAME.LocalBackend,
        log: :debug
      ] ++ get_worker_pool_config(cfg)

    {FLAME.Pool, opts}
  end

  defp get_worker_pool_config(cfg) do
    worker_pool_config = Map.get(cfg, "workerPool", %{})

    [
      min: Map.get(worker_pool_config, "min", 0),
      max: Map.get(worker_pool_config, "max", 10),
      max_concurrency: Map.get(worker_pool_config, "maxConcurrency", 100),
      boot_timeout: Map.get(worker_pool_config, "bootTimeout", 30000),
      timeout: Map.get(worker_pool_config, "callTimeout", 30000),
      single_use: Map.get(worker_pool_config, "oneOff", "false"),
      idle_shutdown_after: Map.get(worker_pool_config, "idleShutdownAfter", 30000)
    ]
  end
end
