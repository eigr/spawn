defmodule SpawnOperator.K8sConn do
  @moduledoc """
  Initializes the %K8s.Conn{} struct depending on the mix environment. To be used in config.exs (bonny.exs):

  ```
  # Function to call to get a K8s.Conn object.
  # The function should return a %K8s.Conn{} struct or a {:ok, %K8s.Conn{}} tuple
  get_conn: {SpawnOperator.K8sConn, :get, [config_env()]},
  ```
  """

  @spec get(atom()) :: K8s.Conn.t()
  def get(:dev) do
    {:ok, conn} = K8s.Conn.from_file("~/.kube/config", context: "k3d-k3d-eigr-spawn")
    struct!(conn, insecure_skip_tls_verify: true)
  end

  def get(:test) do
    conn = %K8s.Conn{
      discovery_driver: K8s.Discovery.Driver.File,
      discovery_opts: [config: "test/support/discovery.json"],
      http_provider: K8s.Client.DynamicHTTPProvider
    }

    struct!(conn, insecure_skip_tls_verify: true)
  end

  def get(:prod) do
    K8s.Conn.from_service_account()
    |> then(fn
      {:ok, conn} ->
        # TODO It is a workaround and needed to be removed
        struct!(conn, insecure_skip_tls_verify: true)

      other ->
        other
    end)
  end

  def get(_) do
    K8s.Conn.from_service_account()
    |> then(fn
      {:ok, conn} -> conn
      other -> other
    end)
  end
end
