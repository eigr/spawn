defmodule Spawn.Cluster.ClusterResolver do
  @moduledoc false

  use GenServer
  use Cluster.Strategy
  import Cluster.Logger

  alias Cluster.Strategy.State

  @default_polling_interval 5_000

  @impl true
  def start_link(args), do: GenServer.start_link(__MODULE__, args)

  @impl true
  def init([%State{meta: nil} = state]) do
    init([%State{state | :meta => MapSet.new()}])
  end

  def init([%State{} = state]) do
    {:ok, load(state), 0}
  end

  @impl true
  def handle_info(:timeout, state) do
    handle_info(:load, state)
  end

  def handle_info(:load, state) do
    {:noreply, load(state)}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  defp load(%State{topology: topology, meta: meta} = state) do
    new_nodelist = MapSet.new(get_nodes(state))
    removed = MapSet.difference(meta, new_nodelist)

    new_nodelist =
      case Cluster.Strategy.disconnect_nodes(
             topology,
             state.disconnect,
             state.list_nodes,
             MapSet.to_list(removed)
           ) do
        :ok ->
          new_nodelist

        {:error, bad_nodes} ->
          # Add back the nodes which should have been removed, but which couldn't be for some reason
          Enum.reduce(bad_nodes, new_nodelist, fn {n, _}, acc ->
            MapSet.put(acc, n)
          end)
      end

    new_nodelist =
      case Cluster.Strategy.connect_nodes(
             topology,
             state.connect,
             state.list_nodes,
             MapSet.to_list(new_nodelist)
           ) do
        :ok ->
          new_nodelist

        {:error, bad_nodes} ->
          # Remove the nodes which should have been added, but couldn't be for some reason
          Enum.reduce(bad_nodes, new_nodelist, fn {n, _}, acc ->
            MapSet.delete(acc, n)
          end)
      end

    Process.send_after(
      self(),
      :load,
      polling_interval(state)
    )

    %State{state | meta: new_nodelist}
  end

  @spec get_nodes(State.t()) :: [atom()]
  defp get_nodes(%State{topology: topology, config: config}) do
    app_name = Keyword.fetch!(config, :application_name)
    service = Keyword.fetch!(config, :service)
    resolver = Keyword.get(config, :resolver, &:inet_res.getbyname(&1, :a))

    IO.inspect(app_name, label: "Using application name ---------------------")
    IO.inspect(service, label: "Using service ---------------------")
    IO.inspect(resolver, label: "Using resolver ---------------------")
    IO.inspect(Node.get_cookie(), label: "Using node cookie ---------------------")

    cond do
      app_name != nil and service != nil ->
        headless_service = to_charlist(service)

        IO.inspect(headless_service, label: "Using headless service ---------------------")

        case resolver.(headless_service) do
          {:ok, {:hostent, _fqdn, [], :inet, _value, addresses}} ->
            IO.inspect(addresses, label: "Using addresses ---------------------")
            parse_response(addresses, app_name)

          {:error, reason} ->
            error(topology, "lookup against #{service} failed: #{inspect(reason)}")
            []
        end

      app_name == nil ->
        warn(
          topology,
          "kubernetes.DNS strategy is selected, but :application_name is not configured!"
        )

        []

      service == nil ->
        warn(topology, "kubernetes strategy is selected, but :service is not configured!")
        []

      :else ->
        warn(topology, "kubernetes strategy is selected, but is not configured!")
        []
    end
  end

  defp polling_interval(%State{config: config}) do
    Keyword.get(config, :polling_interval, @default_polling_interval)
  end

  defp parse_response(addresses, app_name) do
    addresses
    |> Enum.map(&:inet_parse.ntoa(&1))
    |> Enum.map(&"#{app_name}@#{&1}")
    |> Enum.map(&String.to_atom(&1))
    |> IO.inspect(label: "Parsed addresses ---------------------")
  end
end
