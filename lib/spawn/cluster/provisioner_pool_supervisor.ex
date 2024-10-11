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
        build_flame_pool(cfg, env)
      end)

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp build_flame_pool(%{"actorName" => name} = cfg, env) do
    pool_name = build_worker_pool_name(__MODULE__, name)
    Logger.info("Creating pool for Actor #{name}. Pool Name: #{inspect(pool_name)}")

    opts =
      [
        name: pool_name,
        backend: pool_backend(cfg, env),
        log: :debug
      ] ++ get_worker_pool_config(cfg)

    {FLAME.Pool, opts}
  end

  defp pool_backend(cfg, :prod) do
    {FLAMEK8sBackend,
     app_container_name: "sidecar",
     runner_pod_tpl: fn current_manifest -> build_pod_template(cfg, current_manifest) end}
  end

  defp pool_backend(_, _env), do: FLAME.LocalBackend

  defp get_worker_pool_config(cfg) do
    worker_pool_config = Map.get(cfg, "workerPool", %{})

    [
      min: Map.get(worker_pool_config, "min", 0),
      max: Map.get(worker_pool_config, "max", 10),
      max_concurrency: Map.get(worker_pool_config, "maxConcurrency", 100),
      single_use: Map.get(worker_pool_config, "oneOff", "false"),
      timeout: Map.get(worker_pool_config, "callTimeout", :infinity),
      boot_timeout: Map.get(worker_pool_config, "bootTimeout", :timer.minutes(3)),
      idle_shutdown_after: Map.get(worker_pool_config, "idleShutdownAfter", :timer.minutes(1)),
      track_resources: true
    ]
  end

  defp build_pod_template(cfg, template) do
    Logger.debug("Building pod template...")

    template
    |> update_pod_metadata()
    |> update_pod_spec()
    |> remove_probes_from_containers()
    |> maybe_put_node_selector(cfg)
    |> maybe_put_toleration(cfg)
  end

  defp update_pod_metadata(template) do
    target_metadata = %{
      "name" => "target-pod",
      "namespace" => Access.get(template, "metadata")["namespace"],
      "annotations" => %{
        "prometheus.io/path" => "/metrics",
        "prometheus.io/port" => "9001",
        "prometheus.io/scrape" => "true"
      }
    }

    put_in(template["metadata"], target_metadata)
  end

  defp update_pod_spec(template) do
    spec = template["spec"]

    target_spec = %{
      "initContainers" => spec["initContainers"],
      "containers" => spec["containers"],
      "volumes" => spec["volumes"],
      "serviceAccount" => spec["serviceAccount"],
      "serviceAccountName" => spec["serviceAccountName"],
      "terminationGracePeriodSeconds" => spec["terminationGracePeriodSeconds"],
      "restartPolicy" => "Never"
    }

    put_in(template["spec"], target_spec)
  end

  defp remove_probes_from_containers(template) do
    updated_containers =
      template["spec"]["containers"]
      |> Enum.map(&Map.drop(&1, ["readinessProbe", "livenessProbe"]))

    put_in(template["spec"]["containers"], updated_containers)
  end

  defp maybe_put_node_selector(template, %{"topology" => topology}) do
    update_metadata_with_labels(template)
    |> put_in(["spec", "nodeSelector"], topology["nodeSelector"])
  end

  defp maybe_put_node_selector(template, _cfg), do: template

  defp maybe_put_toleration(template, %{"topology" => topology}) do
    update_metadata_with_labels(template)
    |> put_in(["spec", "tolerations"], topology["tolerations"])
  end

  defp maybe_put_toleration(template, _cfg), do: template

  defp update_metadata_with_labels(template) do
    new_label_map =
      template
      |> get_in(["metadata", "labels"])
      |> Kernel.||(%{})
      |> Map.merge(%{"io.eigr.spawn/worker" => "true"})

    put_in(template["metadata"]["labels"], new_label_map)
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
end
