defmodule SpawnSdk.System.Supervisor do
  @moduledoc """
  Documentation for `System.Supervisor`.

  Start Supervisor tree like this:

    defmodule MyApp.Application do
      use Application

      @impl true
      def start(_type, _args) do
        children = [
          {
            SpawnSdk.System.Supervisor,
            system: "my-system", actors: [MyActor]
          }
        ]

        opts = [strategy: :one_for_one, name: MyApp.Supervisor]
        Supervisor.start_link(children, opts)
    end
  """
  use Supervisor

  alias Actors.Config.Vapor, as: Config

  @impl true
  def init(opts) do
    config = Config.load(__MODULE__)

    unless _system = opts[:system] do
      raise ArgumentError, "expected :system option to be given"
    end

    unless _actors = opts[:actors] do
      raise ArgumentError, "expected :actors option to be given"
    end

    system = Keyword.get(opts, :system)
    actors = Keyword.get(opts, :actors)
    extenal_subscribers = Keyword.get(opts, :extenal_subscribers, [])

    if config.actor_system_name != system do
      raise ArgumentError,
            "configured system (#{inspect(system)}) is different from env PROXY_ACTOR_SYSTEM_NAME (#{config.actor_system_name})"
    end

    start_persisted_system(system)

    children =
      [
        {Sidecar.Supervisor, config},
        %{
          id: :spawn_system_register_task,
          start:
            {Task, :start_link,
             [
               fn ->
                 Process.flag(:trap_exit, true)

                 SpawnSdk.System.SpawnSystem.register(system, actors)

                 receive do
                   {:EXIT, _pid, _reason} ->
                     :persistent_term.erase(system)

                     :ok
                 end
               end
             ]}
        }
      ] ++ extenal_subscribers

    Supervisor.init(children, strategy: :one_for_one)
  end

  def start_link(state) do
    Supervisor.start_link(
      __MODULE__,
      state,
      shutdown: 120_000,
      strategy: :one_for_one
    )
  end

  defp start_persisted_system(system) do
    if :persistent_term.get(system, false) do
      raise "System already registered"
    else
      :persistent_term.put(system, true)
      :ets.new(:"#{system}:actors", [:public, :named_table, read_concurrency: true])
    end
  end
end
