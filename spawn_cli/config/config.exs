import Config

config :do_it, DoIt.Commfig,
  dirname: System.user_home(),
  filename: "spawn_cli.json"
