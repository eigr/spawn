import Config

config :bonny,
  get_conn: {K8s.Conn, :from_file, ["~/.kube/config", [context: "kind-default"]]}
