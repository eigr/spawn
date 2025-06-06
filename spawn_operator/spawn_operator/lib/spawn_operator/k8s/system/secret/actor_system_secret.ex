defmodule SpawnOperator.K8s.System.Secret.ActorSystemSecret do
  @moduledoc false

  @behaviour SpawnOperator.K8s.Manifest

  import Bonny.Config, only: [conn: 0]

  @erlang_profiles %{
    insecure_erl_flags:
      "+C multi_time_warp -mode embedded +sbwt none +sbwtdcpu none +sbwtdio none",
    tls_erl_flags:
      " -proto_dist inet_tls -ssl_dist_optfile /app/mtls.ssl.conf +C multi_time_warp -mode embedded +sbwt none +sbwtdcpu none +sbwtdio none"
  }

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
      |> maybe_use_nats_cluster(name, ns, cluster_params)

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

    features =
      Map.get(params, "features", %{"erlangMtls" => %{"enabled" => false}})

    erlang_mtls_enabled =
      Map.get(features, "erlangMtls", %{})
      |> Map.get("enabled", false)

    erlang_profile =
      if erlang_mtls_enabled,
        do: @erlang_profiles.tls_erl_flags,
        else: @erlang_profiles.insecure_erl_flags

    case String.to_existing_atom(kind) do
      :erlang ->
        cookie = Map.get(params, "cookie", default_cookie(ns)) |> Base.encode64()
        cluster_poolling = "3000" |> Base.encode64()
        cluster_strategy = "kubernetes-dns" |> Base.encode64()
        cluster_service = "system-#{system}" |> Base.encode64()
        cluster_heartbeat = "240000" |> Base.encode64()

        %{
          "ERL_CLUSTER_MTLS_ENABLED" => Base.encode64("#{erlang_mtls_enabled}"),
          "ERL_FLAGS" => Base.encode64(erlang_profile),
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
        }

      _other ->
        %{}
    end
  end

  defp maybe_use_nats_cluster(config, _name, namespace, params) do
    features =
      Map.get(params, "features", %{
        "nats" => %{
          "enabled" => false,
          "url" => "nats://nats.eigr-functions.svc.cluster.local:4222",
          "credentialsSecretRef" => "nats-connectin-secret"
        }
      })

    nats_params = Map.get(features, "nats", %{})

    nats_enabled =
      Map.get(nats_params, "enabled")

    nats_url =
      Map.get(nats_params, "url")

    nats_config =
      case nats_enabled do
        false ->
          %{}

        true ->
          nats_secret_ref = Map.fetch!(nats_params, "credentialsSecretRef")

          {:ok, secret} =
            K8s.Client.get("v1", :secret,
              namespace: "eigr-functions",
              name: nats_secret_ref
            )
            |> then(&K8s.Client.run(conn(), &1))

          secret_data = Map.get(secret, "data")
          nats_host_url = nats_url |> Base.encode64()
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
