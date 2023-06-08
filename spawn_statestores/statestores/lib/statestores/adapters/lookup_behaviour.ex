defmodule Statestores.Adapters.LookupBehaviour do
  @moduledoc """
  `LookupBehaviour` defines how system get clustered actors info.
  """
  @type actor_id :: struct()

  @type host :: struct()

  @doc """
  Delete all records from a specific node.
  """
  @callback clean(node()) :: {:error, any()} | {:ok, any()}

  @doc """
  Retrieves all actohost entries for a specific node.
  """
  @callback get_all_by_node(node()) :: {:ok, any()} | {:error, any()}

  @doc """
  Fetches all existing entries for a given ActorId.
  """
  @callback get_by_id(actor_id) :: {:ok, any()} | {:error, any()}

  @doc """
  Fetches all existing entries for a given ActorId for a specific node.
  """
  @callback get_by_id_node(actor_id, node()) :: {:ok, any()} | {:error, any()}

  @doc """
  Saves or updates to persistent storage the ActorHost for a given ActorId.
  """
  @callback set(actor_id(), node(), host()) :: {:error, any()} | {:ok, any()}

  defmacro __using__(_opts) do
    quote do
      alias Statestores.Adapters.LookupBehaviour
      import Ecto.Query, only: [from: 2]
      import Statestores.Util, only: [init_config: 1, generate_key: 1]

      @behaviour Statestores.Adapters.LookupBehaviour

      def init(_type, config), do: init_config(config)
    end
  end
end
