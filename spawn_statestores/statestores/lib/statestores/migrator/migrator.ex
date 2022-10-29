defmodule Statestores.Migrator do
  import Statestores.Util, only: [load_app: 0]

  @spec migrate(module()) :: {:ok, any, any}
  def migrate(adapter) do
    load_app()

    adapter.migrate()
  end

  @spec rollback(any, any) :: {:ok, any, any}
  def rollback(adapter, version) do
    load_app()

    adapter.rollback(version)
  end
end
