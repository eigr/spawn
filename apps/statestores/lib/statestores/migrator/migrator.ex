defmodule Statestores.Migrator do
  @otp_app :statestores

  def migrate do
    load_app()
    type = String.to_existing_atom(System.get_env("PROXY_DATABASE_TYPE"))
    repo = load_repo(type)

    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp load_app do
    Application.load(@otp_app)
  end

  defp load_repo(:mysql), do: Statestores.Adapters.MySQL

  defp load_repo(:postgres), do: Statestores.Adapters.Postgres

end
