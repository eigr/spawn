import Config

config :proxy,
  http_port: System.get_env("PROXY_HTTP_PORT", "9001") |> String.to_integer()

import_config "../../../config/config.exs"
