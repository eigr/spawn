defmodule Statestores.Adapters.NativeLookupAdapter do
  @moduledoc """
  Implements the behavior defined in `Statestores.Adapters.LookupBehaviour` for MySql databases.
  """
  use Statestores.Adapters.LookupBehaviour
  use GenServer

  @impl true
  def clean(_node), do: raise("Not implemented")

  @impl true
  def get_all_by_node(_node), do: raise("Not implemented")

  @impl true
  def get_by_id(_id), do: raise("Not implemented")

  @impl true
  def get_by_id_node(_id, _node), do: raise("Not implemented")

  @impl true
  def set(_id, _node, _data), do: raise("Not implemented")

  def child_spec(_),
    do: %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []}
    }

  def start_link, do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @impl GenServer
  def init(_), do: {:ok, nil}
end
