import Config

if config_env() == :prod do
  config :logger,
    level: String.to_atom(System.get_env("SPAWN_PROXY_LOGGER_LEVEL", "info"))
end
