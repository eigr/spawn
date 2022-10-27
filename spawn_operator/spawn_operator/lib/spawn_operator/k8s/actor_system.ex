defmodule SpawnOperator.K8s.ActorSystem do
  @moduledoc false

  @behaviour SpawnOperator.K8s.Manifest

  import Bonny.Config, only: [conn: 0]

  @impl true
  def manifest(system, ns, name, params), do: gen_configmap(system, ns, name, params)

  defp gen_configmap(system, ns, name, params) do
    IO.inspect(params, label: "Initial Params")
    mesh_params = Map.get(params, "mesh", %{})
    statestore_params = Map.get(params, "statestore", %{})

    distributed_options = get_dist_options(system, ns, mesh_params)
    IO.inspect(distributed_options, label: "Distributed Options")
    storage_options = get_storage_options(system, ns, statestore_params)
    IO.inspect(storage_options, label: "Storage Options")

    %{
      "apiVersion" => "v1",
      "kind" => "ConfigMap",
      "metadata" => %{
        "name" => "#{system}-cm",
        "namespace" => ns
      },
      "data" => Map.merge(distributed_options, storage_options)
    }
  end

  defp get_storage_options(system, ns, params) do
    statestore = String.downcase(Map.get(params, "type", "native"))
    statestore_key = Map.fetch!(params, "statestoreCryptoKey")
    statestore_db_name = Map.get(params, "databaseName", "eigr-functions-db")
    statestore_db_host = Map.get(params, "databaseHost")
    statestore_db_port = Map.get(params, "databasePort")
    pool_params = Map.get(params, "pool", %{})
    pool_size = Map.get(pool_params, "size", "10")
    statestore_credentials_secret_ref = Map.fetch!(params, "credentialsSecretRef")

    {:ok, secret} =
      K8s.Client.get("v1", :secret,
        namespace: ns,
        name: statestore_credentials_secret_ref
      )
      |> then(&K8s.Client.run(conn(), &1))

    secret_data = Map.fetch!(secret, "data")
    statestore_db_user = Map.fetch!(secret_data, "username")
    statestore_db_secret = Map.fetch!(secret_data, "password")

    %{
      "PROXY_DATABASE_TYPE" => statestore,
      "PROXY_DATABASE_NAME" => statestore_db_name,
      "PROXY_DATABASE_HOST" => statestore_db_host,
      "PROXY_DATABASE_PORT" => statestore_db_port,
      "PROXY_DATABASE_USERNAME" => statestore_db_user,
      "PROXY_DATABASE_SECRET" => statestore_db_secret,
      "PROXY_DATABASE_POOL_SIZE" => pool_size,
      "SPAWN_STATESTORE_KEY" => statestore_key
    }
  end

  defp get_dist_options(system, ns, params) do
    kind = Map.get(params, "kind", "erlang")

    case String.to_existing_atom(kind) do
      :erlang ->
        cookie = Map.get(params, "cookie", default_cookie(ns))

        %{
          "NODE_COOKIE" => cookie,
          "PROXY_CLUSTER_POLLING" => "3000",
          "PROXY_CLUSTER_STRATEGY" => "kubernetes-dns",
          "PROXY_HEADLESS_SERVICE" => "system-#{system}-svc",
          "PROXY_HEARTBEAT_INTERVAL" => "240000"
        }

      :quic ->
        %{
          "PROXY_CLUSTER_STRATEGY" => "quic_dist",
          "PROXY_HEADLESS_SERVICE" => "system-#{system}-svc",
          "PROXY_TLS_CERT_PATH" => "",
          "PROXY_TLS_KEY_PATH" => ""
        }

      _other ->
        %{}
    end
  end

  defp default_cookie(ns),
    do: "#{ns}-#{:crypto.hash(:md5, ns) |> Base.encode16(case: :lower)}"
end
