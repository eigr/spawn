import Config

config :bonny,
  get_conn: {K8s.Conn, :from_service_account, []}
