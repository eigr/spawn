defmodule Statestores.Supervisor do
  @moduledoc false
  use Supervisor

  import Statestores.Util, only: [load_adapter: 0, get_adapter_children: 0]

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def child_spec() do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [[]]}
    }
  end

  @impl true
  def init(_args) do
    adapter = load_adapter()
    adapter_children = get_adapter_children()
    Statestores.Config.load()
    Statestores.Migrator.migrate(adapter)

    children =
      [Statestores.Vault]
      |> maybe_add_adapter(adapter)
      |> maybe_add_adapter_children(adapter_children)

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp maybe_add_adapter(children, Statestores.Adapters.Native), do: children
  defp maybe_add_adapter(children, adapter), do: children ++ [adapter]
  defp maybe_add_adapter_children(children, adapter_children), do: children ++ adapter_children
end
