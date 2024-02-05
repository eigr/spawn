defmodule Statestores.SandboxHelper do
  @moduledoc false

  defmacro __using__(args) do
    quote do
      setup _tags do
        repos = unquote(args[:repos])

        Enum.each(repos, fn repo ->
          if repo in [Statestores.Adapters.NativeSnapshotAdapter, Statestores.Adapters.NativeLookupAdapter] do
            :mnesia.clear_table(Statestores.Adapters.NativeSnapshotAdapter)
          end
        end)

        on_exit(fn ->
          Enum.each(repos, fn repo ->
            if repo in [Statestores.Adapters.NativeSnapshotAdapter, Statestores.Adapters.NativeLookupAdapter] do
              :mnesia.clear_table(Statestores.Adapters.NativeSnapshotAdapter)
            end
          end)
        end)
      end
    end
  end
end
