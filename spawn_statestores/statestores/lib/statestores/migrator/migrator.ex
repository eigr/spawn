defmodule Statestores.Migrator do
  @moduledoc """
  Run database migrations
  """
  import Statestores.Util, only: [load_app: 0]

  def migrate(adapter) do
    load_app()

    if adapter not in [
         Statestores.Adapters.NativeSnapshotAdapter,
         Statestores.Adapters.NativeLookupAdapter
       ] do
      {:ok, _, _} = Ecto.Migrator.with_repo(adapter, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  @spec rollback(any, any) :: {:ok, any, any}
  def rollback(adapter, version) do
    load_app()

    if adapter not in [
         Statestores.Adapters.NativeSnapshotAdapter,
         Statestores.Adapters.NativeLookupAdapter
       ] do
      {:ok, _, _} = Ecto.Migrator.with_repo(adapter, &Ecto.Migrator.run(&1, :down, to: version))
    end
  end
end
