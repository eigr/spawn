defmodule Actors.Security.Tls.Initializer do
  @moduledoc """
  This module must be used by initializing the container via initContainers

  ```
  initContainers:
    - args:
        - eval
        - Kompost.Webhooks.bootstrap_tls(:prod, "tls-certs")
      image: docker.io/eigr/spawn-proxy:1.0.0-rc.17
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
      {:ok, ca_bundle}
    else
      error ->
        Logger.error("TLS Bootstrap failed: #{inspect(error)}")
        exit({:shutdown, 1})
    end
  end
end
