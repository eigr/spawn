defmodule SpawnOperator.K8s.Secret.ActorSystemSecret do
  @moduledoc false

  @behaviour SpawnOperator.K8s.Manifest

  import Bonny.Config, only: [conn: 0]

  @impl true
  def manifest(resource, _opts \\ []), do: gen_secret(resource)

  defp gen_secret(
         %{
           system: system,
           namespace: ns,
           name: _name,
           params: params,
           labels: _labels,
           annotations: _annotations
         } = _resource
       ) do
    cluster_params = Map.get(params, "cluster", %{})
    statestore_params = Map.get(params, "statestore", %{})

    distributed_options = get_dist_options(system, ns, cluster_params)
    storage_options = get_storage_options(system, ns, statestore_params)

    %{
      "apiVersion" => "v1",
      "kind" => "Secret",
      "metadata" => %{
        "name" => "#{system}-secret",
        "namespace" => ns
      },
      "data" => Map.merge(distributed_options, storage_options)
    }
  end

  defp get_storage_options(_system, ns, params) do
    statestore = String.downcase(Map.get(params, "type", "native")) |> Base.encode64()
    pool_params = Map.get(params, "pool", %{})
    pool_size = Map.get(pool_params, "size", "10") |> Base.encode64()
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
    statestore_key = Map.fetch!(secret_data, "encryptionKey")
    statestore_db_name = Map.get(secret_data, "database", "eigr-functions-db")
    statestore_db_host = Map.get(secret_data, "host")
    statestore_db_port = Map.get(secret_data, "port")

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
        cookie = Map.get(params, "cookie", default_cookie(ns)) |> Base.encode64()
        cluster_poolling = "3000" |> Base.encode64()
        cluster_strategy = "kubernetes-dns" |> Base.encode64()
        cluster_service = "system-#{system}-svc" |> Base.encode64()
        cluster_heartbeat = "240000" |> Base.encode64()

        %{
          "NODE_COOKIE" => cookie,
          "PROXY_CLUSTER_POLLING" => cluster_poolling,
          "PROXY_CLUSTER_STRATEGY" => cluster_strategy,
          "PROXY_HEADLESS_SERVICE" => cluster_service,
          "PROXY_HEARTBEAT_INTERVAL" => cluster_heartbeat
        }

      :quic ->
        cluster_service = "system-#{system}-svc" |> Base.encode64()
        cluster_strategy = "quic_dist" |> Base.encode64()

        %{
          "PROXY_CLUSTER_STRATEGY" => cluster_strategy,
          "PROXY_HEADLESS_SERVICE" => cluster_service
          # "PROXY_TLS_CERT_PATH" => "",
          # "PROXY_TLS_KEY_PATH" => ""
        }

      _other ->
        %{}
    end
  end

  defp default_cookie(ns),
    do:
      "cookie-#{:crypto.hash(:md5, ns) |> Base.encode16(case: :lower)}-#{:crypto.strong_rand_bytes(32) |> Base.encode64(case: :lower)}"
end
