defmodule SpawnOperator.K8s.System.Secret.ActorSystemSecret do
  @moduledoc false

  @behaviour SpawnOperator.K8s.Manifest

  import Bonny.Config, only: [conn: 0]

  @impl true
  def manifest(resource, _opts \\ []), do: gen_secret(resource)

  defp gen_secret(
         %{
           system: _system,
           namespace: ns,
           name: name,
           params: params,
           labels: _labels,
           annotations: _annotations
         } = _resource
       ) do
    cluster_params = Map.get(params, "cluster", %{})
    statestore_params = Map.get(params, "statestore", %{})

    distributed_options = get_dist_options(name, ns, cluster_params)
    storage_options = get_storage_options(name, ns, statestore_params)

    data =
      Map.merge(distributed_options, storage_options)
      |> maybe_use_nats_cluster(name, ns, params)

    %{
      "apiVersion" => "v1",
      "kind" => "Secret",
      "metadata" => %{
        "name" => "#{name}-secret",
        "namespace" => String.downcase(name)
      },
      "data" => data
    }
  end

  defp get_storage_options(_system, _ns, params) do
    statestore = String.downcase(Map.get(params, "type", "native")) |> Base.encode64()
    pool_params = Map.get(params, "pool", %{})
    pool_size = "#{Map.get(pool_params, "size", 10)}" |> Base.encode64()
    statestore_credentials_secret_ref = Map.get(params, "credentialsSecretRef", "none")
    statestore_ssl = "#{Map.get(params, "ssl", "false")}" |> Base.encode64()
    statestore_ssl_verify = "#{Map.get(params, "ssl_verify", "false")}" |> Base.encode64()

    if statestore == "native" do
      %{
        "PROXY_DATABASE_TYPE" => statestore
        # TODO check if encryption key is necessary
        # "SPAWN_STATESTORE_KEY" => statestore_key,
      }
    else
      {:ok, secret} =
        K8s.Client.get("v1", :secret,
          namespace: "eigr-functions",
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
        "SPAWN_STATESTORE_KEY" => statestore_key,
        "PROXY_DATABASE_SSL" => statestore_ssl,
        "PROXY_DATABASE_SSL_VERIFY" => statestore_ssl_verify
      }
    end
  end

  defp get_dist_options(system, ns, params) do

    kind = Map.get(params, "kind", "erlang")

    case String.to_existing_atom(kind) do
      :erlang ->
        cookie = Map.get(params, "cookie", default_cookie(ns)) |> Base.encode64()
        cluster_poolling = "3000" |> Base.encode64()
        cluster_strategy = "kubernetes-dns" |> Base.encode64()
        cluster_service = "system-#{system}" |> Base.encode64()
        cluster_heartbeat = "240000" |> Base.encode64()

        %{
          "RELEASE_COOKIE" => cookie,
          "PROXY_ACTOR_SYSTEM_NAME" => Base.encode64(system),
          "PROXY_CLUSTER_POLLING" => cluster_poolling,
          "PROXY_CLUSTER_STRATEGY" => cluster_strategy,
          "PROXY_HEADLESS_SERVICE" => cluster_service,
          "PROXY_HEARTBEAT_INTERVAL" => cluster_heartbeat
        }

      :quic ->
        cluster_service = "system-#{system}" |> Base.encode64()
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

  defp maybe_use_nats_cluster(config, _name, namespace, params) do
    cluster_params = Map.get(params, "cluster", %{})
    features = Map.get(cluster_params, "features", %{})
    nats_params = Map.get(features, "nats", %{})
    enabled = "#{Map.get(nats_params, "enabled", false)}"

    nats_config =
      case enabled do
        "false" ->
          %{}

        "true" ->
          nats_secret_ref = Map.fetch!(nats_params, "credentialsSecretRef")

          {:ok, secret} =
            K8s.Client.get("v1", :secret,
              namespace: namespace,
              name: nats_secret_ref
            )
            |> then(&K8s.Client.run(conn(), &1))

          secret_data = Map.get(secret, "data")
          nats_host_url = Map.get(secret_data, "url", nats_params["url"])
          nats_auth = Map.get(secret_data, "authEnabled", "false")
          nats_user = Map.get(secret_data, "username")
          nats_secret = Map.get(secret_data, "password")
          nats_tls = Map.get(secret_data, "tlsEnabled", "false")

          %{
            "SPAWN_USE_INTERNAL_NATS" => Base.encode64("true"),
            "SPAWN_INTERNAL_NATS_HOSTS" => nats_host_url,
            "SPAWN_INTERNAL_NATS_TLS" => nats_tls,
            "SPAWN_INTERNAL_NATS_AUTH" => nats_auth,
            "SPAWN_INTERNAL_NATS_AUTH_USER" => nats_user,
            "SPAWN_INTERNAL_NATS_AUTH_PASS" => nats_secret
          }
      end

    Map.merge(config, nats_config)
  end

  defp default_cookie(ns),
    do:
      "cookie-#{:crypto.hash(:md5, ns) |> Base.encode16(case: :lower)}-#{:crypto.strong_rand_bytes(32) |> Base.encode64(case: :lower)}"
end
