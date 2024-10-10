import Config

config :do_it, DoIt.Commfig,
  dirname: System.tmp_dir(),
  filename: "spawn_cli.json"

config :flame, :terminator, failsafe_timeout: :timer.minuts(1)
