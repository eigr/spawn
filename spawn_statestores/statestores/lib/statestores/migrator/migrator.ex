defmodule Statestores.Migrator do
  @moduledoc """
  Run database migrations
  """
  import Statestores.Util, only: [load_app: 0]

  @spec migrate(module()) :: {:ok, any, any}
  def migrate(adapter) do
    load_app()

    {:ok, _, _} = Ecto.Migrator.with_repo(adapter, &Ecto.Migrator.run(&1, :up, all: true))
  end

  @spec rollback(any, any) :: {:ok, any, any}
  def rollback(adapter, version) do
    load_app()

    {:ok, _, _} = Ecto.Migrator.with_repo(adapter, &Ecto.Migrator.run(&1, :down, to: version))
  end
end
