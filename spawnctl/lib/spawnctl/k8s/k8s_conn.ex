defmodule SpawnCtl.K8s.K8sConn do
  @moduledoc """
  Initializes the %K8s.Conn{} struct depending on the mix environment. To be used in config.exs (bonny.exs):

  ```
  # Function to call to get a K8s.Conn object.
  # The function should return a %K8s.Conn{} struct or a {:ok, %K8s.Conn{}} tuple
  get_conn: {SpawnCtl.K8s.K8sConn, :get, [config_env(), "k3d-eigr-spawn"]},
  ```
  """

  @spec get(atom()) :: K8s.Conn.t()
  def get(:test) do
    conn = %K8s.Conn{
      discovery_driver: K8s.Discovery.Driver.File,
      discovery_opts: [config: "test/support/discovery.json"],
      http_provider: K8s.Client.DynamicHTTPProvider
    }

    struct!(conn, insecure_skip_tls_verify: true)
  end

  def get(_) do
    K8s.Conn.from_service_account()
    |> then(fn
      {:ok, conn} -> conn
      other -> other
    end)
  end

  @spec get(atom(), String.t()) :: K8s.Conn.t()
  def get(:dev, context) do
    case K8s.Conn.from_file("~/.kube/config", context: context) do
      {:ok, conn} ->
        struct!(conn, insecure_skip_tls_verify: true)

      error ->
        error
    end
  end

  def get(:prod, context) do
    case K8s.Conn.from_file("~/.kube/config", context: context) do
      {:ok, conn} ->
        struct!(conn, insecure_skip_tls_verify: true)

      error ->
        error
    end
  end

  @spec get(atom(), String.t(), String.t()) :: K8s.Conn.t()
  def get(:dev, kube_config, context) do
    case K8s.Conn.from_file(kube_config, context: context) do
      {:ok, conn} ->
        struct!(conn, insecure_skip_tls_verify: true)

      error ->
        error
    end
  end

  def get(:prod, kube_config, context) do
    case K8s.Conn.from_file(kube_config, context: context) do
      {:ok, conn} ->
        struct!(conn, insecure_skip_tls_verify: true)

      error ->
        error
    end
  end

  @spec get_from_env(atom(), String.t(), String.t()) :: K8s.Conn.t()
  def get_from_env(:dev, env, context) do
    case K8s.Conn.from_env(env, insecure_skip_tls_verify: true, context: context) do
      {:ok, conn} ->
        conn

      error ->
        error
    end
  end

  def get_from_env(:prod, env, context) do
    case K8s.Conn.from_env(env, insecure_skip_tls_verify: true, context: context) do
      {:ok, conn} ->
        conn

      error ->
        error
    end
  end
end
