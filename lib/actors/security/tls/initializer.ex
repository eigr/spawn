defmodule Actors.Security.Tls.Initializer do
  @moduledoc """
  This module must be used by initializing the container via initContainers

  ```
  initContainers:
    - args:
        - eval
        - Kompost.Webhooks.bootstrap_tls(:prod, "tls-certs")
      image: ghcr.io/mruoss/kompost:0.3.0@sha256:4924bb78afbffe0a41a952bc77855a29761d5908a35fca3ac88836cf27b49190
      name: init-certificates
  serviceAccountName: kompost
  volumes:
    - name: certs
      secret:
        optional: true
        secretName: tls-certs
  ```
  """

  alias Actors.K8s.K8sConn

  require Logger

  @spec bootstrap_tls(atom(), binary(), binary(), binary(), binary()) :: :ok
  def bootstrap_tls(env, secret_name, service_namespace, service_name, secret_namespace) do
    Application.ensure_all_started(:k8s)
    conn = K8sConn.get!(env)

    with {:certs, {:ok, ca_bundle}} <-
           {:certs,
            K8sWebhoox.ensure_certificates(
              conn,
              service_namespace,
              service_name,
              secret_namespace,
              secret_name
            )} do
      Logger.info("TLS Bootstrap completed.")
    else
      error ->
        Logger.error("TLS Bootstrap failed: #{inspect(error)}")
        exit({:shutdown, 1})
    end
  end
end
