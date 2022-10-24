defmodule Statestores.SandboxHelper do
  @moduledoc false

  defmacro __using__(args) do
    quote do
      setup _tags do
        repos = unquote(args[:repos])

        Enum.each(repos, fn repo ->
          :ok = Ecto.Adapters.SQL.Sandbox.checkout(repo)
          Ecto.Adapters.SQL.Sandbox.mode(repo, :auto)
        end)

        on_exit(fn ->
          Enum.each(repos, fn repo ->
            :ok = Ecto.Adapters.SQL.Sandbox.checkout(repo)
            Ecto.Adapters.SQL.Sandbox.mode(repo, :auto)
          end)
        end)
      end
    end
  end
end
